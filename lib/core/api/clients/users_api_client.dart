import '../base_api_client.dart';

class UsersApiClient extends BaseApiClient {
  const UsersApiClient(super.dio);

  Future<Map<String, dynamic>> me() {
    return requestJson(() => dio.get<Map<String, dynamic>>('/users/me'));
  }

  Future<List<dynamic>> index() {
    return requestList(() => dio.get<List<dynamic>>('/users'));
  }

  Future<Map<String, dynamic>> invite({
    required String email,
    required String name,
  }) {
    return requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/users/invitations',
        data: {'email': email, 'name': name},
      ),
    );
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> payload) {
    return requestJson(
      () => dio.patch<Map<String, dynamic>>('/users/me', data: payload),
    );
  }

  Future<void> registerFcmToken(String token) async {
    await requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/users/me/fcm_token',
        data: {'token': token},
      ),
    );
  }
}
