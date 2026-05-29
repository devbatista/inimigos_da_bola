import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/db/database_providers.dart';
import '../../data/stats_repository.dart';
import 'stats_controller.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(
    database: ref.watch(appDatabaseProvider),
    weeklySessionsDao: ref.watch(weeklySessionsDaoProvider),
    attendancesDao: ref.watch(attendancesDaoProvider),
    usersDao: ref.watch(usersDaoProvider),
    sessionStatsDao: ref.watch(sessionStatsDaoProvider),
    syncDao: ref.watch(syncDaoProvider),
  );
});

final statsControllerProvider =
    ChangeNotifierProvider.autoDispose<StatsController>((ref) {
      final controller = StatsController(ref.watch(statsRepositoryProvider));
      unawaited(controller.load());
      return controller;
    });
