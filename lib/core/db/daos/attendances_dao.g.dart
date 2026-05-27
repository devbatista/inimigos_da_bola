// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendances_dao.dart';

// ignore_for_file: type=lint
mixin _$AttendancesDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $WeeklySessionsTable get weeklySessions => attachedDatabase.weeklySessions;
  $AttendancesTable get attendances => attachedDatabase.attendances;
  AttendancesDaoManager get managers => AttendancesDaoManager(this);
}

class AttendancesDaoManager {
  final _$AttendancesDaoMixin _db;
  AttendancesDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$WeeklySessionsTableTableManager get weeklySessions =>
      $$WeeklySessionsTableTableManager(
        _db.attachedDatabase,
        _db.weeklySessions,
      );
  $$AttendancesTableTableManager get attendances =>
      $$AttendancesTableTableManager(_db.attachedDatabase, _db.attendances);
}
