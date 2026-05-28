import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/db/database_providers.dart';
import '../../data/teams_draw_repository.dart';
import 'teams_draw_controller.dart';

final teamsDrawRepositoryProvider = Provider<TeamsDrawRepository>((ref) {
  return TeamsDrawRepository(
    weeklySessionsApiClient: ref.watch(weeklySessionsApiClientProvider),
    syncApiClient: ref.watch(syncApiClientProvider),
    weeklySessionsDao: ref.watch(weeklySessionsDaoProvider),
    usersDao: ref.watch(usersDaoProvider),
    attendancesDao: ref.watch(attendancesDaoProvider),
  );
});

// AutoDispose: o sorteio é uma ferramenta de quadra; ao sair da tela, o
// estado some por design (a próxima rodada começa do zero).
final teamsDrawControllerProvider =
    ChangeNotifierProvider.autoDispose<TeamsDrawController>((ref) {
      final controller = TeamsDrawController(
        ref.watch(teamsDrawRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });
