import 'package:drift/drift.dart';

import '../../../core/api/clients/guest_attendances_api_client.dart';
import '../../../core/api/clients/sync_api_client.dart';
import '../../../core/api/clients/weekly_sessions_api_client.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/attendances_dao.dart';
import '../../../core/db/daos/users_dao.dart';
import '../../../core/db/daos/weekly_sessions_dao.dart';

class GuestAttendanceRepository {
  const GuestAttendanceRepository({
    required WeeklySessionsApiClient weeklySessionsApiClient,
    required GuestAttendancesApiClient guestAttendancesApiClient,
    required SyncApiClient syncApiClient,
    required UsersDao usersDao,
    required WeeklySessionsDao weeklySessionsDao,
    required AttendancesDao attendancesDao,
  }) : _weeklySessionsApiClient = weeklySessionsApiClient,
       _guestAttendancesApiClient = guestAttendancesApiClient,
       _syncApiClient = syncApiClient,
       _usersDao = usersDao,
       _weeklySessionsDao = weeklySessionsDao,
       _attendancesDao = attendancesDao;

  final WeeklySessionsApiClient _weeklySessionsApiClient;
  final GuestAttendancesApiClient _guestAttendancesApiClient;
  final SyncApiClient _syncApiClient;
  final UsersDao _usersDao;
  final WeeklySessionsDao _weeklySessionsDao;
  final AttendancesDao _attendancesDao;

  Future<GuestAttendanceData> load() async {
    final currentSessionJson = await _weeklySessionsApiClient.current();
    await _upsertWeeklySession(currentSessionJson);
    await _pullLatest();

    return _readData(currentSessionJson['id'] as String);
  }

  Future<GuestAttendanceData> create({
    required GuestAttendanceData current,
    required String guestName,
  }) async {
    final attendanceJson = await _guestAttendancesApiClient.create(
      weeklySessionId: current.session.id,
      guestName: guestName,
    );
    await _upsertAttendance(attendanceJson);

    return _readData(current.session.id);
  }

  Future<GuestAttendanceData> delete({
    required GuestAttendanceData current,
    required String attendanceId,
  }) async {
    await _guestAttendancesApiClient.delete(
      weeklySessionId: current.session.id,
      attendanceId: attendanceId,
    );
    await _attendancesDao.deleteAttendance(attendanceId);
    await _pullLatest();

    return _readData(current.session.id);
  }

  Future<void> _pullLatest() async {
    final syncJson = await _syncApiClient.pull(
      entities: const ['users', 'weekly_sessions', 'attendances'],
    );
    final entities = syncJson['entities'];
    if (entities is! Map<String, dynamic>) {
      return;
    }

    for (final user in _entityList(entities, 'users')) {
      await _upsertUser(user);
    }

    for (final weeklySession in _entityList(entities, 'weekly_sessions')) {
      await _upsertWeeklySession(weeklySession);
    }

    for (final attendance in _entityList(entities, 'attendances')) {
      await _upsertAttendance(attendance);
    }
  }

  Future<GuestAttendanceData> _readData(String sessionId) async {
    final session = await _weeklySessionsDao.findActiveById(sessionId);
    final attendances = await _attendancesDao.listByWeeklySession(sessionId);

    return GuestAttendanceData(
      session: session ?? _fallbackSession(sessionId),
      guests: attendances
          .where((attendance) => attendance.kind == 'guest')
          .toList(),
      updatedAt: DateTime.now(),
    );
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

  WeeklySession _fallbackSession(String sessionId) {
    final now = DateTime.now();
    return WeeklySession(
      id: sessionId,
      scheduledAt: now,
      maxPlayers: 20,
      status: 'scheduled',
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
    );
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
        kind: Value(json['kind'] as String? ?? 'guest'),
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

class GuestAttendanceData {
  const GuestAttendanceData({
    required this.session,
    required this.guests,
    required this.updatedAt,
  });

  final WeeklySession session;
  final List<Attendance> guests;
  final DateTime updatedAt;
}
