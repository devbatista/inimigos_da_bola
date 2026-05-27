import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/core/api/api_client.dart';
import 'package:inimigos_da_bola/core/config/app_config.dart';

void main() {
  test('configura baseUrl e headers padrão do Dio', () {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.example.test/api/v1'),
    );

    expect(client.dio.options.baseUrl, 'https://api.example.test/api/v1');
    expect(client.dio.options.headers['Accept'], 'application/json');
    expect(client.dio.options.headers['Content-Type'], 'application/json');
  });
}
