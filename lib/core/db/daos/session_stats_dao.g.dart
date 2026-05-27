// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_stats_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionStatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeeklySessionsTable get weeklySessions => attachedDatabase.weeklySessions;
  $UsersTable get users => attachedDatabase.users;
  $SessionStatsTable get sessionStats => attachedDatabase.sessionStats;
  SessionStatsDaoManager get managers => SessionStatsDaoManager(this);
}

class SessionStatsDaoManager {
  final _$SessionStatsDaoMixin _db;
  SessionStatsDaoManager(this._db);
  $$WeeklySessionsTableTableManager get weeklySessions =>
      $$WeeklySessionsTableTableManager(
        _db.attachedDatabase,
        _db.weeklySessions,
      );
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$SessionStatsTableTableManager get sessionStats =>
      $$SessionStatsTableTableManager(_db.attachedDatabase, _db.sessionStats);
}
