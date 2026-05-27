// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$WeeklySessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeeklySessionsTable get weeklySessions => attachedDatabase.weeklySessions;
  WeeklySessionsDaoManager get managers => WeeklySessionsDaoManager(this);
}

class WeeklySessionsDaoManager {
  final _$WeeklySessionsDaoMixin _db;
  WeeklySessionsDaoManager(this._db);
  $$WeeklySessionsTableTableManager get weeklySessions =>
      $$WeeklySessionsTableTableManager(
        _db.attachedDatabase,
        _db.weeklySessions,
      );
}
