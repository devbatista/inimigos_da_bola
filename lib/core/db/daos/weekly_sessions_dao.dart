import 'package:drift/drift.dart';

import '../app_database.dart';

part 'weekly_sessions_dao.g.dart';

@DriftAccessor(tables: [WeeklySessions])
class WeeklySessionsDao extends DatabaseAccessor<AppDatabase>
    with _$WeeklySessionsDaoMixin {
  WeeklySessionsDao(super.db);

  Stream<List<WeeklySession>> watchActiveWeeklySessions() {
    return (select(weeklySessions)
          ..where((session) => session.deletedAt.isNull())
          ..orderBy([(session) => OrderingTerm.desc(session.scheduledAt)]))
        .watch();
  }

  Future<WeeklySession?> latestActiveWeeklySession() {
    return (select(weeklySessions)
          ..where((session) => session.deletedAt.isNull())
          ..orderBy([(session) => OrderingTerm.desc(session.scheduledAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<WeeklySession?> findActiveById(String id) {
    return (select(weeklySessions)..where(
          (session) => session.id.equals(id) & session.deletedAt.isNull(),
        ))
        .getSingleOrNull();
  }

  Future<void> upsertWeeklySession(WeeklySessionsCompanion weeklySession) {
    return into(weeklySessions).insertOnConflictUpdate(weeklySession);
  }
}
