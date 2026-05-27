import '../base_api_client.dart';

class SkillRatingsApiClient extends BaseApiClient {
  const SkillRatingsApiClient(super.dio);

  Future<Map<String, dynamic>> createOrUpdate({
    required String evaluatedUserId,
    required int score,
  }) {
    return requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/skill_ratings',
        data: {'evaluated_user_id': evaluatedUserId, 'score': score},
      ),
    );
  }
}
