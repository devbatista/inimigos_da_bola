import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromDio(DioException exception) {
    final response = exception.response;
    final parsed = _parseResponseData(response?.data);

    return ApiException(
      code: parsed.code,
      message: parsed.message,
      statusCode: response?.statusCode,
    );
  }

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() {
    return 'ApiException($statusCode, $code, $message)';
  }

  static _ParsedError _parseResponseData(Object? data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return _ParsedError(
          code: error['code'] as String? ?? 'unknown_error',
          message: error['message'] as String? ?? 'Erro inesperado.',
        );
      }
    }

    return const _ParsedError(
      code: 'network_error',
      message: 'Não foi possível concluir a requisição.',
    );
  }
}

class _ParsedError {
  const _ParsedError({required this.code, required this.message});

  final String code;
  final String message;
}
