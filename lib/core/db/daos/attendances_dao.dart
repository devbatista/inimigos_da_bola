import 'package:drift/drift.dart';

import '../app_database.dart';

part 'attendances_dao.g.dart';

@DriftAccessor(tables: [Attendances])
class AttendancesDao extends DatabaseAccessor<AppDatabase>
    with _$AttendancesDaoMixin {
  AttendancesDao(super.db);

  Stream<List<Attendance>> watchByWeeklySession(String weeklySessionId) {
    return (select(attendances)..where(
          (attendance) =>
              attendance.weeklySessionId.equals(weeklySessionId) &
              attendance.deletedAt.isNull(),
        ))
        .watch();
  }

  Future<void> upsertAttendance(AttendancesCompanion attendance) {
    return into(attendances).insertOnConflictUpdate(attendance);
  }
}
