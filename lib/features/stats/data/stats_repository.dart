import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/attendances_dao.dart';
import '../../../core/db/daos/session_stats_dao.dart';
import '../../../core/db/daos/sync_dao.dart';
import '../../../core/db/daos/users_dao.dart';
import '../../../core/db/daos/weekly_sessions_dao.dart';
import '../../../core/ids/uuid_v7.dart';

class StatsRepository {
  StatsRepository({
    required AppDatabase database,
    required WeeklySessionsDao weeklySessionsDao,
    required AttendancesDao attendancesDao,
    required UsersDao usersDao,
    required SessionStatsDao sessionStatsDao,
    required SyncDao syncDao,
    UuidV7? ids,
  }) : _database = database,
       _weeklySessionsDao = weeklySessionsDao,
       _attendancesDao = attendancesDao,
       _usersDao = usersDao,
       _sessionStatsDao = sessionStatsDao,
       _syncDao = syncDao,
       _ids = ids ?? UuidV7();

  final AppDatabase _database;
  final WeeklySessionsDao _weeklySessionsDao;
  final AttendancesDao _attendancesDao;
  final UsersDao _usersDao;
  final SessionStatsDao _sessionStatsDao;
  final SyncDao _syncDao;
  final UuidV7 _ids;

  Future<StatsData> load() async {
    final session = await _weeklySessionsDao.latestActiveWeeklySession();
    final users = await _usersDao.listActiveUsers();
    final leaderboardStats = await _sessionStatsDao.listActiveStats();

    if (session == null) {
      return StatsData(
        session: null,
        players: const [],
        leaderboard: _buildLeaderboard(users: users, stats: leaderboardStats),
      );
    }

    final attendances = await _attendancesDao.listByWeeklySession(session.id);
    final sessionStats = await _sessionStatsDao.listByWeeklySession(session.id);
    final statsByUserId = {for (final stat in sessionStats) stat.userId: stat};
    final usersById = {for (final user in users) user.id: user};

    final confirmedPlayers =
        attendances
            .where(
              (attendance) =>
                  attendance.kind == 'registered' &&
                  attendance.status == 'confirmed' &&
                  attendance.waitlistPosition == null &&
                  attendance.userId != null,
            )
            .map((attendance) => usersById[attendance.userId])
            .whereType<User>()
            .toList()
          ..sort((first, second) => first.name.compareTo(second.name));

    return StatsData(
      session: session,
      players: [
        for (final user in confirmedPlayers)
          StatsPlayerEntry(user: user, stat: statsByUserId[user.id]),
      ],
      leaderboard: _buildLeaderboard(users: users, stats: leaderboardStats),
    );
  }

  Future<StatsData> saveSessionStats({
    required String weeklySessionId,
    required List<StatsInput> inputs,
  }) async {
    final currentStats = await _sessionStatsDao.listByWeeklySession(
      weeklySessionId,
    );
    final statsByUserId = {for (final stat in currentStats) stat.userId: stat};
    final now = DateTime.now();

    await _database.transaction(() async {
      for (final input in inputs) {
        final existing = statsByUserId[input.userId];
        final id = existing?.id ?? _ids.generate();
        final operation = existing == null ? 'create' : 'update';
        final createdAt = existing?.createdAt ?? now;
        final version = (existing?.version ?? 0) + 1;
        final record = {
          'id': id,
          'weekly_session_id': weeklySessionId,
          'user_id': input.userId,
          'goals': input.goals,
          'assists': input.assists,
          'created_at': createdAt.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
          'deleted_at': null,
          'version': version,
        };

        await _sessionStatsDao.upsertSessionStat(
          SessionStatsCompanion.insert(
            id: id,
            weeklySessionId: weeklySessionId,
            userId: input.userId,
            goals: Value(input.goals),
            assists: Value(input.assists),
            createdAt: createdAt,
            updatedAt: now,
            deletedAt: const Value(null),
            version: Value(version),
          ),
        );

        await _syncDao.enqueueMutation(
          SyncQueueCompanion.insert(
            id: _ids.generate(),
            entity: 'session_stats',
            entityId: id,
            operation: operation,
            mutationId: _ids.generate(),
            payloadJson: jsonEncode(record),
            createdAt: now,
          ),
        );
      }
    });

    return load();
  }

  List<LeaderboardEntry> _buildLeaderboard({
    required List<User> users,
    required List<SessionStat> stats,
  }) {
    final usersById = {for (final user in users) user.id: user};
    final totals = <String, _StatTotal>{};

    for (final stat in stats) {
      if (!usersById.containsKey(stat.userId)) {
        continue;
      }

      final total = totals.putIfAbsent(stat.userId, _StatTotal.new);
      total.goals += stat.goals;
      total.assists += stat.assists;
    }

    final entries =
        [
          for (final entry in totals.entries)
            LeaderboardEntry(
              user: usersById[entry.key]!,
              goals: entry.value.goals,
              assists: entry.value.assists,
            ),
        ]..sort((first, second) {
          final goalsComparison = second.goals.compareTo(first.goals);
          if (goalsComparison != 0) {
            return goalsComparison;
          }

          final assistsComparison = second.assists.compareTo(first.assists);
          if (assistsComparison != 0) {
            return assistsComparison;
          }

          return first.user.name.compareTo(second.user.name);
        });

    return entries;
  }
}

class StatsData {
  const StatsData({
    required this.session,
    required this.players,
    required this.leaderboard,
  });

  final WeeklySession? session;
  final List<StatsPlayerEntry> players;
  final List<LeaderboardEntry> leaderboard;
}

class StatsPlayerEntry {
  const StatsPlayerEntry({required this.user, required this.stat});

  final User user;
  final SessionStat? stat;
}

class StatsInput {
  const StatsInput({
    required this.userId,
    required this.goals,
    required this.assists,
  });

  final String userId;
  final int goals;
  final int assists;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.user,
    required this.goals,
    required this.assists,
  });

  final User user;
  final int goals;
  final int assists;
}

class _StatTotal {
  int goals = 0;
  int assists = 0;
}
