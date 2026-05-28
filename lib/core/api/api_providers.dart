import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'clients/attendances_api_client.dart';
import 'clients/sync_api_client.dart';
import 'clients/users_api_client.dart';
import 'clients/weekly_sessions_api_client.dart';

final weeklySessionsApiClientProvider = Provider<WeeklySessionsApiClient>((
  ref,
) {
  return WeeklySessionsApiClient(ref.watch(apiClientProvider).dio);
});

final attendancesApiClientProvider = Provider<AttendancesApiClient>((ref) {
  return AttendancesApiClient(ref.watch(apiClientProvider).dio);
});

final usersApiClientProvider = Provider<UsersApiClient>((ref) {
  return UsersApiClient(ref.watch(apiClientProvider).dio);
});

final syncApiClientProvider = Provider<SyncApiClient>((ref) {
  return SyncApiClient(ref.watch(apiClientProvider).dio);
});
