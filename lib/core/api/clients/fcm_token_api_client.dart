import '../base_api_client.dart';

class FcmTokenApiClient extends BaseApiClient {
  const FcmTokenApiClient(super.dio);

  Future<void> register(String token) async {
    await requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/users/me/fcm_token',
        data: {'token': token},
      ),
    );
  }
}
