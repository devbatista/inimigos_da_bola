import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../api/api_client.dart';
import '../api/clients/auth_api_client.dart';
import '../config/app_config.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'token_storage.dart';

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final refreshClient = RefreshTokenClient(config: config);

  return ApiClient(
    config: config,
    tokenStorage: tokenStorage,
    refreshTokens: refreshClient.refresh,
  );
});

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApiClient(apiClient.dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authApiClient: ref.watch(authApiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  unawaited(controller.bootstrap());
  return controller;
});
