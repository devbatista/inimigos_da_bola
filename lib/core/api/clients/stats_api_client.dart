import '../base_api_client.dart';

class StatsApiClient extends BaseApiClient {
  const StatsApiClient(super.dio);

  Future<Map<String, dynamic>> saveBatch({
    required String weeklySessionId,
    required List<Map<String, dynamic>> stats,
  }) {
    return requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/weekly_sessions/$weeklySessionId/stats',
        data: {'stats': stats},
      ),
    );
  }
}
