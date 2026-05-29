import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/core/db/app_database.dart';
import 'package:inimigos_da_bola/core/ids/uuid_v7.dart';
import 'package:inimigos_da_bola/features/stats/data/stats_repository.dart';

void main() {
  late AppDatabase database;
  late StatsRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = StatsRepository(
      database: database,
      weeklySessionsDao: database.weeklySessionsDao,
      attendancesDao: database.attendancesDao,
      usersDao: database.usersDao,
      sessionStatsDao: database.sessionStatsDao,
      syncDao: database.syncDao,
      ids: UuidV7(random: Random(1), now: () => DateTime.utc(2026, 5, 28, 22)),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('lista apenas jogadores cadastrados confirmados', () async {
    final now = DateTime.utc(2026, 5, 28, 20);
    await _seedBase(database, now);

    final data = await repository.load();

    expect(data.players.map((entry) => entry.user.name), ['Ana', 'João']);
  });

  test('salva stats localmente e enfileira sync', () async {
    final now = DateTime.utc(2026, 5, 28, 20);
    await _seedBase(database, now);

    await repository.saveSessionStats(
      weeklySessionId: _sessionId,
      inputs: const [
        StatsInput(userId: _anaId, goals: 2, assists: 1),
        StatsInput(userId: _joaoId, goals: 1, assists: 0),
      ],
    );

    final stats = await database.sessionStatsDao.listByWeeklySession(
      _sessionId,
    );
    final mutations = await database.syncDao.watchPendingMutations().first;

    expect(stats, hasLength(2));
    expect(stats.firstWhere((stat) => stat.userId == _anaId).goals, 2);
    expect(mutations, hasLength(2));
    expect(
      mutations.every((mutation) => mutation.entity == 'session_stats'),
      isTrue,
    );

    final payload = jsonDecode(mutations.first.payloadJson);
    expect(payload['weekly_session_id'], _sessionId);
  });

  test('ranking soma gols e assistências do cache local', () async {
    final now = DateTime.utc(2026, 5, 28, 20);
    await _seedBase(database, now);
    await repository.saveSessionStats(
      weeklySessionId: _sessionId,
      inputs: const [
        StatsInput(userId: _anaId, goals: 1, assists: 3),
        StatsInput(userId: _joaoId, goals: 2, assists: 0),
      ],
    );

    final data = await repository.load();

    expect(data.leaderboard.first.user.name, 'João');
    expect(data.leaderboard.first.goals, 2);
    expect(data.leaderboard.last.assists, 3);
  });
}

const _sessionId = '01971f8c-2222-7000-8000-000000000002';
const _anaId = '01971f8c-1111-7000-8000-000000000001';
const _joaoId = '01971f8c-1111-7000-8000-000000000002';
const _waitlistId = '01971f8c-1111-7000-8000-000000000003';

Future<void> _seedBase(AppDatabase database, DateTime now) async {
  await database.usersDao.upsertUser(
    UsersCompanion.insert(
      id: _anaId,
      email: 'ana@example.com',
      name: 'Ana',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await database.usersDao.upsertUser(
    UsersCompanion.insert(
      id: _joaoId,
      email: 'joao@example.com',
      name: 'João',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await database.usersDao.upsertUser(
    UsersCompanion.insert(
      id: _waitlistId,
      email: 'maria@example.com',
      name: 'Maria',
      createdAt: now,
      updatedAt: now,
    ),
  );

  await database.weeklySessionsDao.upsertWeeklySession(
    WeeklySessionsCompanion.insert(
      id: _sessionId,
      scheduledAt: now,
      createdAt: now,
      updatedAt: now,
    ),
  );

  await database.attendancesDao.upsertAttendance(
    AttendancesCompanion.insert(
      id: '01971f8c-3333-7000-8000-000000000001',
      weeklySessionId: _sessionId,
      userId: const Value(_anaId),
      status: const Value('confirmed'),
      createdAt: now,
      updatedAt: now,
    ),
  );
  await database.attendancesDao.upsertAttendance(
    AttendancesCompanion.insert(
      id: '01971f8c-3333-7000-8000-000000000002',
      weeklySessionId: _sessionId,
      userId: const Value(_joaoId),
      status: const Value('confirmed'),
      createdAt: now,
      updatedAt: now,
    ),
  );
  await database.attendancesDao.upsertAttendance(
    AttendancesCompanion.insert(
      id: '01971f8c-3333-7000-8000-000000000003',
      weeklySessionId: _sessionId,
      userId: const Value(_waitlistId),
      status: const Value('confirmed'),
      waitlistPosition: const Value(1),
      createdAt: now,
      updatedAt: now,
    ),
  );
}
