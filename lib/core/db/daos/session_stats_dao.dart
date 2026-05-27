import 'package:drift/drift.dart';

import '../app_database.dart';

part 'session_stats_dao.g.dart';

@DriftAccessor(tables: [SessionStats])
class SessionStatsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionStatsDaoMixin {
  SessionStatsDao(super.db);

  Stream<List<SessionStat>> watchByWeeklySession(String weeklySessionId) {
    return (select(sessionStats)..where(
          (stat) =>
              stat.weeklySessionId.equals(weeklySessionId) &
              stat.deletedAt.isNull(),
        ))
        .watch();
  }

  Future<void> upsertSessionStat(SessionStatsCompanion sessionStat) {
    return into(sessionStats).insertOnConflictUpdate(sessionStat);
  }
}
