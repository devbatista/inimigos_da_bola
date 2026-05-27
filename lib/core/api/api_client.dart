import 'package:dio/dio.dart';

import '../auth/auth_tokens.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    AppConfig config = const AppConfig(),
    TokenStorage? tokenStorage,
    TokenRefresher? refreshTokens,
    Dio? dio,
  }) : dio = dio ?? Dio(_baseOptions(config)) {
    final storage = tokenStorage;
    final refresher = refreshTokens;

    if (storage != null && refresher != null) {
      this.dio.interceptors.add(
        AuthInterceptor(
          dio: this.dio,
          tokenStorage: storage,
          refreshTokens: refresher,
        ),
      );
    }
  }

  final Dio dio;

  static BaseOptions _baseOptions(AppConfig config) {
    return BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }
}

class RefreshTokenClient {
  RefreshTokenClient({AppConfig config = const AppConfig(), Dio? dio})
    : _dio = dio ?? Dio(ApiClient._baseOptions(config));

  final Dio _dio;

  Future<AuthTokens?> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
    );

    final data = response.data;
    if (data == null) {
      return null;
    }

    return AuthTokens.fromJson(data);
  }
}
