import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/db/database_providers.dart';
import '../../data/settings_repository.dart';
import 'settings_controller.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    usersApiClient: ref.watch(usersApiClientProvider),
    usersDao: ref.watch(usersDaoProvider),
  );
});

final settingsControllerProvider =
    ChangeNotifierProvider.autoDispose<SettingsController>((ref) {
      final controller = SettingsController(
        ref.watch(settingsRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });
