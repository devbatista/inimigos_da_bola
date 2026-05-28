import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/attendances_dao.dart';
import 'daos/users_dao.dart';
import 'daos/weekly_sessions_dao.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final usersDaoProvider = Provider<UsersDao>((ref) {
  return ref.watch(appDatabaseProvider).usersDao;
});

final weeklySessionsDaoProvider = Provider<WeeklySessionsDao>((ref) {
  return ref.watch(appDatabaseProvider).weeklySessionsDao;
});

final attendancesDaoProvider = Provider<AttendancesDao>((ref) {
  return ref.watch(appDatabaseProvider).attendancesDao;
});
