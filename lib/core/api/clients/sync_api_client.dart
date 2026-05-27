import 'package:dio/dio.dart';

import '../base_api_client.dart';

class SyncApiClient extends BaseApiClient {
  const SyncApiClient(super.dio);

  Future<Map<String, dynamic>> push({
    required String entity,
    required String mutationId,
    required String operation,
    required Map<String, dynamic> record,
  }) {
    return requestJson(
      () => dio.post<Map<String, dynamic>>(
        '/sync/$entity',
        data: {'op': operation, 'record': record},
        options: Options(headers: {'Idempotency-Key': mutationId}),
      ),
    );
  }

  Future<Map<String, dynamic>> pull({DateTime? since, List<String>? entities}) {
    return requestJson(
      () => dio.get<Map<String, dynamic>>(
        '/sync',
        queryParameters: {
          if (since != null) 'since': since.toUtc().toIso8601String(),
          if (entities != null && entities.isNotEmpty)
            'entities': entities.join(','),
        },
      ),
    );
  }
}
