import 'package:dio/dio.dart';

import '../auth/auth_tokens.dart';
import '../auth/token_storage.dart';

typedef TokenRefresher = Future<AuthTokens?> Function(String refreshToken);

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required TokenRefresher refreshTokens,
  }) : _dio = dio,
       _tokenStorage = tokenStorage,
       _refreshTokens = refreshTokens;

  static const skipAuthKey = 'skipAuth';
  static const retryKey = 'authRetry';

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final TokenRefresher _refreshTokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true) {
      return handler.next(options);
    }

    final tokens = await _tokenStorage.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) {
      return handler.next(err);
    }

    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      return handler.next(err);
    }

    final refreshedTokens = await _refreshTokens(tokens.refreshToken);
    if (refreshedTokens == null) {
      await _tokenStorage.clear();
      return handler.next(err);
    }

    await _tokenStorage.save(refreshedTokens);

    final requestOptions = err.requestOptions;
    requestOptions.extra[retryKey] = true;
    requestOptions.headers['Authorization'] =
        'Bearer ${refreshedTokens.accessToken}';

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRefresh(DioException err) {
    final response = err.response;
    if (response?.statusCode != 401) {
      return false;
    }

    if (err.requestOptions.extra[skipAuthKey] == true ||
        err.requestOptions.extra[retryKey] == true) {
      return false;
    }

    final data = response?.data;
    if (data is! Map<String, dynamic>) {
      return false;
    }

    final error = data['error'];
    return error is Map<String, dynamic> && error['code'] == 'token_expired';
  }
}
