import 'package:drift/drift.dart';

import '../../../core/api/clients/sync_api_client.dart';
import '../../../core/api/clients/weekly_sessions_api_client.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/attendances_dao.dart';
import '../../../core/db/daos/users_dao.dart';
import '../../../core/db/daos/weekly_sessions_dao.dart';
import '../domain/draw_algorithm.dart';

class TeamsDrawRepository {
  const TeamsDrawRepository({
    required WeeklySessionsApiClient weeklySessionsApiClient,
    required SyncApiClient syncApiClient,
    required WeeklySessionsDao weeklySessionsDao,
    required UsersDao usersDao,
    required AttendancesDao attendancesDao,
  }) : _weeklySessionsApiClient = weeklySessionsApiClient,
       _syncApiClient = syncApiClient,
       _weeklySessionsDao = weeklySessionsDao,
       _usersDao = usersDao,
       _attendancesDao = attendancesDao;

  final WeeklySessionsApiClient _weeklySessionsApiClient;
  final SyncApiClient _syncApiClient;
  final WeeklySessionsDao _weeklySessionsDao;
  final UsersDao _usersDao;
  final AttendancesDao _attendancesDao;

  Future<List<DrawParticipant>> loadConfirmedParticipants() async {
    final currentSessionJson = await _weeklySessionsApiClient.current();
    final syncJson = await _syncApiClient.pull(
      entities: const ['users', 'weekly_sessions', 'attendances'],
    );

    await _upsertWeeklySession(currentSessionJson);
    await _applySync(syncJson);

    final sessionId = currentSessionJson['id'] as String;
    return _buildParticipants(sessionId);
  }

  Future<List<DrawParticipant>> _buildParticipants(String sessionId) async {
    final attendances = await _attendancesDao.listByWeeklySession(sessionId);
    final users = await _usersDao.listActiveUsers();
    final usersById = {for (final user in users) user.id: user};

    final participants = <DrawParticipant>[];
    for (final attendance in attendances) {
      if (attendance.status != 'confirmed' ||
          attendance.waitlistPosition != null) {
        continue;
      }

      if (attendance.kind == 'guest') {
        participants.add(
          DrawParticipant(
            id: attendance.id,
            name: attendance.guestName ?? 'Avulso',
            kind: DrawParticipantKind.guest,
          ),
        );
      } else {
        final user = usersById[attendance.userId];
        if (user == null) {
          continue;
        }
        participants.add(
          DrawParticipant(
            id: user.id,
            name: user.name,
            kind: DrawParticipantKind.registered,
            skillScore: user.skillScore,
            goalkeeper: user.goalkeeper,
          ),
        );
      }
    }

    participants.sort((first, second) => first.name.compareTo(second.name));
    return participants;
  }

  Future<void> _applySync(Map<String, dynamic> syncJson) async {
    final entities = syncJson['entities'];
    if (entities is! Map<String, dynamic>) {
      return;
    }

    for (final json in _entityList(entities, 'users')) {
      await _upsertUser(json);
    }
    for (final json in _entityList(entities, 'weekly_sessions')) {
      await _upsertWeeklySession(json);
    }
    for (final json in _entityList(entities, 'attendances')) {
      await _upsertAttendance(json);
    }
  }

  List<Map<String, dynamic>> _entityList(
    Map<String, dynamic> entities,
    String name,
  ) {
    final records = entities[name];
    if (records is! List) {
      return const [];
    }
    return records.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _upsertUser(Map<String, dynamic> json) {
    final now = DateTime.now();
    return _usersDao.upsertUser(
      UsersCompanion.insert(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        createdAt: _date(json['created_at']) ?? now,
        updatedAt: _date(json['updated_at']) ?? now,
        phone: Value(json['phone'] as String?),
        admin: Value(json['admin'] as bool? ?? false),
        playerType: Value(json['player_type'] as String? ?? 'casual'),
        skillScore: Value(_double(json['skill_score'])),
        goalkeeper: Value(json['goalkeeper'] as bool? ?? false),
        deletedAt: Value(_date(json['deleted_at'])),
        version: Value(json['version'] as int? ?? 1),
      ),
    );
  }

  Future<void> _upsertWeeklySession(Map<String, dynamic> json) {
    final now = DateTime.now();
    return _weeklySessionsDao.upsertWeeklySession(
      WeeklySessionsCompanion.insert(
        id: json['id'] as String,
        scheduledAt: _date(json['scheduled_at']) ?? now,
        createdAt: _date(json['created_at']) ?? now,
        updatedAt: _date(json['updated_at']) ?? now,
        maxPlayers: Value(json['max_players'] as int? ?? 20),
        status: Value(json['status'] as String? ?? 'scheduled'),
        deletedAt: Value(_date(json['deleted_at'])),
        version: Value(json['version'] as int? ?? 1),
      ),
    );
  }

  Future<void> _upsertAttendance(Map<String, dynamic> json) {
    final now = DateTime.now();
    return _attendancesDao.upsertAttendance(
      AttendancesCompanion.insert(
        id: json['id'] as String,
        weeklySessionId: json['weekly_session_id'] as String,
        createdAt: _date(json['created_at']) ?? now,
        updatedAt: _date(json['updated_at']) ?? now,
        userId: Value(json['user_id'] as String?),
        kind: Value(json['kind'] as String? ?? 'registered'),
        guestName: Value(json['guest_name'] as String?),
        createdByAdminId: Value(json['created_by_admin_id'] as String?),
        status: Value(json['status'] as String? ?? 'pending'),
        waitlistPosition: Value(json['waitlist_position'] as int?),
        deletedAt: Value(_date(json['deleted_at'])),
        version: Value(json['version'] as int? ?? 1),
      ),
    );
  }

  DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value).toLocal();
  }

  double? _double(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
