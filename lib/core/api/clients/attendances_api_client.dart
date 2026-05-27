import '../base_api_client.dart';

class AttendancesApiClient extends BaseApiClient {
  const AttendancesApiClient(super.dio);

  Future<Map<String, dynamic>> confirm({required String weeklySessionId}) {
    return requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/weekly_sessions/$weeklySessionId/attendances',
        data: {'status': 'confirmed'},
      ),
    );
  }

  Future<Map<String, dynamic>> decline({required String weeklySessionId}) {
    return requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/weekly_sessions/$weeklySessionId/attendances',
        data: {'status': 'declined'},
      ),
    );
  }
}
