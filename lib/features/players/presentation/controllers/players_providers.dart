import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/db/database_providers.dart';
import '../../data/players_repository.dart';
import 'players_controller.dart';

final playersRepositoryProvider = Provider<PlayersRepository>((ref) {
  return PlayersRepository(
    usersApiClient: ref.watch(usersApiClientProvider),
    syncApiClient: ref.watch(syncApiClientProvider),
    usersDao: ref.watch(usersDaoProvider),
  );
});

final playersControllerProvider = ChangeNotifierProvider<PlayersController>((
  ref,
) {
  final controller = PlayersController(ref.watch(playersRepositoryProvider));
  unawaited(controller.load());
  return controller;
});
