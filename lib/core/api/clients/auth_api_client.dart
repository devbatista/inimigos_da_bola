import 'package:dio/dio.dart';

import '../../auth/auth_tokens.dart';
import '../auth_interceptor.dart';
import '../base_api_client.dart';

class AuthApiClient extends BaseApiClient {
  const AuthApiClient(super.dio);

  Future<AuthTokens> signIn({
    required String email,
    required String password,
  }) async {
    final json = await requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/auth/sign_in',
        data: {'email': email, 'password': password},
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      ),
    );

    return AuthTokens.fromJson(json);
  }

  Future<AuthTokens> refresh({required String refreshToken}) async {
    final json = await requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      ),
    );

    return AuthTokens.fromJson(json);
  }

  Future<void> signOut() async {
    await requestJson(() => dio.delete<Map<String, dynamic>>('/auth/sign_out'));
  }

  Future<void> requestPasswordReset({required String email}) async {
    await requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/auth/password',
        data: {'email': email},
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      ),
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await requestJson(
      () => dio.put<Map<String, dynamic>>(
        '/auth/password',
        data: {'token': token, 'password': password},
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      ),
    );
  }

  Future<AuthTokens> acceptInvitation({
    required String token,
    required String name,
    required String password,
    required String playerType,
    required bool goalkeeper,
  }) async {
    final json = await requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/users/accept_invitation',
        data: {
          'token': token,
          'name': name,
          'password': password,
          'player_type': playerType,
          'goalkeeper': goalkeeper,
        },
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      ),
    );

    return AuthTokens.fromJson(json);
  }
}
