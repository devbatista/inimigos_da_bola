import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/attendances_dao.dart';
import 'daos/session_stats_dao.dart';
import 'daos/skill_ratings_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/users_dao.dart';
import 'daos/weekly_sessions_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    WeeklySessions,
    Attendances,
    SkillRatings,
    SessionStats,
    SyncQueue,
    SyncState,
  ],
  daos: [
    UsersDao,
    WeeklySessionsDao,
    AttendancesDao,
    SkillRatingsDao,
    SessionStatsDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'inimigos_da_bola'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (migrator, from, to) async {},
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

mixin SyncColumns on Table {
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
}

class Users extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  BoolColumn get admin => boolean().withDefault(const Constant(false))();
  TextColumn get playerType => text().withDefault(const Constant('casual'))();
  RealColumn get skillScore => real().nullable()();
  BoolColumn get goalkeeper => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WeeklySessions extends Table with SyncColumns {
  TextColumn get id => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get maxPlayers => integer().withDefault(const Constant(20))();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Attendances extends Table with SyncColumns {
  TextColumn get id => text()();
  @ReferenceName('registeredAttendances')
  TextColumn get userId => text().nullable().references(Users, #id)();
  TextColumn get weeklySessionId => text().references(WeeklySessions, #id)();
  TextColumn get kind => text().withDefault(const Constant('registered'))();
  TextColumn get guestName => text().nullable()();
  @ReferenceName('createdGuestAttendances')
  TextColumn get createdByAdminId => text().nullable().references(Users, #id)();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get waitlistPosition => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SkillRatings extends Table with SyncColumns {
  TextColumn get id => text()();
  @ReferenceName('givenSkillRatings')
  TextColumn get evaluatorUserId => text().references(Users, #id)();
  @ReferenceName('receivedSkillRatings')
  TextColumn get evaluatedUserId => text().references(Users, #id)();
  IntColumn get score => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SessionStats extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get weeklySessionId => text().references(WeeklySessions, #id)();
  TextColumn get userId => text().references(Users, #id)();
  IntColumn get goals => integer().withDefault(const Constant(0))();
  IntColumn get assists => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get mutationId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncState extends Table {
  TextColumn get entity => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {entity};
}
