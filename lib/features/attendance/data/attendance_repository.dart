import 'package:drift/drift.dart';

import '../../../core/api/clients/attendances_api_client.dart';
import '../../../core/api/clients/sync_api_client.dart';
import '../../../core/api/clients/users_api_client.dart';
import '../../../core/api/clients/weekly_sessions_api_client.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/attendances_dao.dart';
import '../../../core/db/daos/users_dao.dart';
import '../../../core/db/daos/weekly_sessions_dao.dart';

class AttendanceRepository {
  const AttendanceRepository({
    required WeeklySessionsApiClient weeklySessionsApiClient,
    required AttendancesApiClient attendancesApiClient,
    required UsersApiClient usersApiClient,
    required SyncApiClient syncApiClient,
    required UsersDao usersDao,
    required WeeklySessionsDao weeklySessionsDao,
    required AttendancesDao attendancesDao,
  }) : _weeklySessionsApiClient = weeklySessionsApiClient,
       _attendancesApiClient = attendancesApiClient,
       _usersApiClient = usersApiClient,
       _syncApiClient = syncApiClient,
       _usersDao = usersDao,
       _weeklySessionsDao = weeklySessionsDao,
       _attendancesDao = attendancesDao;

  final WeeklySessionsApiClient _weeklySessionsApiClient;
  final AttendancesApiClient _attendancesApiClient;
  final UsersApiClient _usersApiClient;
  final SyncApiClient _syncApiClient;
  final UsersDao _usersDao;
  final WeeklySessionsDao _weeklySessionsDao;
  final AttendancesDao _attendancesDao;

  Future<AttendanceHomeData> load() async {
    final currentUserJson = await _usersApiClient.me();
    final currentSessionJson = await _weeklySessionsApiClient.current();
    final syncJson = await _syncApiClient.pull(
      entities: const ['users', 'weekly_sessions', 'attendances'],
    );

    await _upsertUser(currentUserJson);
    await _upsertWeeklySession(currentSessionJson);
    await _applySync(syncJson);

    final sessionId = currentSessionJson['id'] as String;
    return _readHomeData(
      sessionId: sessionId,
      currentUserId: currentUserJson['id'] as String,
    );
  }

  Future<AttendanceHomeData> confirm(AttendanceHomeData current) async {
    final attendanceJson = await _attendancesApiClient.confirm(
      weeklySessionId: current.session.id,
    );
    await _upsertAttendance(attendanceJson);
    return _readHomeData(
      sessionId: current.session.id,
      currentUserId: current.currentUser.id,
    );
  }

  Future<AttendanceHomeData> decline(AttendanceHomeData current) async {
    final attendanceJson = await _attendancesApiClient.decline(
      weeklySessionId: current.session.id,
    );
    await _upsertAttendance(attendanceJson);
    return _readHomeData(
      sessionId: current.session.id,
      currentUserId: current.currentUser.id,
    );
  }

  Future<void> _applySync(Map<String, dynamic> syncJson) async {
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

  Future<AttendanceHomeData> _readHomeData({
    required String sessionId,
    required String currentUserId,
  }) async {
    final session = await _weeklySessionsDao.findActiveById(sessionId);
    final users = await _usersDao.listActiveUsers();
    final attendances = await _attendancesDao.listByWeeklySession(sessionId);
    final currentUser = users.firstWhere((user) => user.id == currentUserId);

    return AttendanceHomeData(
      session: session ?? _fallbackSession(sessionId),
      currentUser: currentUser,
      attendances: attendances,
      usersById: {for (final user in users) user.id: user},
      updatedAt: DateTime.now(),
    );
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

class AttendanceHomeData {
  const AttendanceHomeData({
    required this.session,
    required this.currentUser,
    required this.attendances,
    required this.usersById,
    required this.updatedAt,
  });

  final WeeklySession session;
  final User currentUser;
  final List<Attendance> attendances;
  final Map<String, User> usersById;
  final DateTime updatedAt;

  List<Attendance> get mainConfirmed {
    return attendances
        .where(
          (attendance) =>
              attendance.status == 'confirmed' &&
              attendance.waitlistPosition == null,
        )
        .toList();
  }

  List<Attendance> get waitlisted {
    return attendances
        .where(
          (attendance) =>
              attendance.status == 'confirmed' &&
              attendance.waitlistPosition != null,
        )
        .toList()
      ..sort(
        (first, second) =>
            first.waitlistPosition!.compareTo(second.waitlistPosition!),
      );
  }

  List<Attendance> get declined {
    return attendances
        .where((attendance) => attendance.status == 'declined')
        .toList();
  }

  List<Attendance> get pending {
    return attendances
        .where((attendance) => attendance.status == 'pending')
        .toList();
  }
}
