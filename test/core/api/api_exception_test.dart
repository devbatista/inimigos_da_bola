import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/core/api/api_exception.dart';

void main() {
  test('parseia erro padrão da API', () {
    final exception = DioException.badResponse(
      statusCode: 422,
      requestOptions: RequestOptions(path: '/users'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/users'),
        statusCode: 422,
        data: {
          'error': {'code': 'invalid_payload', 'message': 'Dados inválidos.'},
        },
      ),
    );

    final apiException = ApiException.fromDio(exception);

    expect(apiException.statusCode, 422);
    expect(apiException.code, 'invalid_payload');
    expect(apiException.message, 'Dados inválidos.');
  });

  test('usa fallback para erro sem corpo padrão', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/sync'),
      type: DioExceptionType.connectionError,
    );

    final apiException = ApiException.fromDio(exception);

    expect(apiException.code, 'network_error');
    expect(apiException.message, 'Não foi possível concluir a requisição.');
  });
}
