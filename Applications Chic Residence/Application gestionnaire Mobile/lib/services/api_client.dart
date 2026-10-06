import 'package:dio/dio.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? token})
      : dio = Dio(BaseOptions(
          baseUrl: ApiConfig.apiBase,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        final msg = _extract(e);
        handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: ApiException(msg, statusCode: e.response?.statusCode),
          response: e.response,
          type: e.type,
        ));
      },
    ));
  }

  final Dio dio;

  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static String _extract(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (e.type == DioExceptionType.connectionError) {
      return 'Serveur injoignable.';
    }
    return e.message ?? 'Erreur inconnue';
  }
}
