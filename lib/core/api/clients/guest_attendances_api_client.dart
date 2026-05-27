import '../base_api_client.dart';

class GuestAttendancesApiClient extends BaseApiClient {
  const GuestAttendancesApiClient(super.dio);

  Future<Map<String, dynamic>> create({
    required String weeklySessionId,
    required String guestName,
  }) {
    return requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/weekly_sessions/$weeklySessionId/guest_attendances',
        data: {'guest_name': guestName},
      ),
    );
  }

  Future<void> delete({
    required String weeklySessionId,
    required String attendanceId,
  }) async {
    await requestJson(
      () => dio.delete<Map<String, dynamic>>(
        '/weekly_sessions/$weeklySessionId/guest_attendances/$attendanceId',
      ),
    );
  }
}
