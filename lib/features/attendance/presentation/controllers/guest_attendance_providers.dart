import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/db/database_providers.dart';
import '../../data/guest_attendance_repository.dart';
import 'guest_attendance_controller.dart';

final guestAttendanceRepositoryProvider = Provider<GuestAttendanceRepository>((
  ref,
) {
  return GuestAttendanceRepository(
    weeklySessionsApiClient: ref.watch(weeklySessionsApiClientProvider),
    guestAttendancesApiClient: ref.watch(guestAttendancesApiClientProvider),
    syncApiClient: ref.watch(syncApiClientProvider),
    usersDao: ref.watch(usersDaoProvider),
    weeklySessionsDao: ref.watch(weeklySessionsDaoProvider),
    attendancesDao: ref.watch(attendancesDaoProvider),
  );
});

final guestAttendanceControllerProvider =
    ChangeNotifierProvider<GuestAttendanceController>((ref) {
      final controller = GuestAttendanceController(
        ref.watch(guestAttendanceRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });
