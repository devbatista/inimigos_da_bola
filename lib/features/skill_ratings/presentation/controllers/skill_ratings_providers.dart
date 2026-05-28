import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/db/database_providers.dart';
import '../../data/skill_ratings_repository.dart';
import 'skill_ratings_controller.dart';

final skillRatingsRepositoryProvider = Provider<SkillRatingsRepository>((ref) {
  return SkillRatingsRepository(
    skillRatingsApiClient: ref.watch(skillRatingsApiClientProvider),
    usersApiClient: ref.watch(usersApiClientProvider),
    syncApiClient: ref.watch(syncApiClientProvider),
    skillRatingsDao: ref.watch(skillRatingsDaoProvider),
    usersDao: ref.watch(usersDaoProvider),
  );
});

final skillRatingsControllerProvider =
    ChangeNotifierProvider<SkillRatingsController>((ref) {
      final controller = SkillRatingsController(
        ref.watch(skillRatingsRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });
