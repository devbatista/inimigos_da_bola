import 'package:dio/dio.dart';

import 'api_exception.dart';

abstract class BaseApiClient {
  const BaseApiClient(this.dio);

  final Dio dio;

  Future<Map<String, dynamic>> requestJson(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return response.data ?? <String, dynamic>{};
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<List<dynamic>> requestList(
    Future<Response<List<dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return response.data ?? <dynamic>[];
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}
