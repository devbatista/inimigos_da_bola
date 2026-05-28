import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/db/database_providers.dart';
import '../../data/attendance_repository.dart';
import 'attendance_controller.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    weeklySessionsApiClient: ref.watch(weeklySessionsApiClientProvider),
    attendancesApiClient: ref.watch(attendancesApiClientProvider),
    usersApiClient: ref.watch(usersApiClientProvider),
    syncApiClient: ref.watch(syncApiClientProvider),
    usersDao: ref.watch(usersDaoProvider),
    weeklySessionsDao: ref.watch(weeklySessionsDaoProvider),
    attendancesDao: ref.watch(attendancesDaoProvider),
  );
});

final attendanceControllerProvider =
    ChangeNotifierProvider<AttendanceController>((ref) {
      final controller = AttendanceController(
        ref.watch(attendanceRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });
