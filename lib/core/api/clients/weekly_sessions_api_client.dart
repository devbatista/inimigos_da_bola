import '../base_api_client.dart';

class WeeklySessionsApiClient extends BaseApiClient {
  const WeeklySessionsApiClient(super.dio);

  Future<Map<String, dynamic>> current() {
    return requestJson(
      () => dio.get<Map<String, dynamic>>('/weekly_sessions/current'),
    );
  }

  Future<List<dynamic>> index() {
    return requestList(() => dio.get<List<dynamic>>('/weekly_sessions'));
  }
}
