import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(
          baseUrl: ApiConfig.apiBase,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final t = await _storage.read(key: ApiConfig.tokenKey);
        if (t != null && t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        handler.next(options);
      },
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
  final _storage = const FlutterSecureStorage();

  Future<void> setToken(String token) =>
      _storage.write(key: ApiConfig.tokenKey, value: token);

  Future<void> clearToken() =>
      _storage.delete(key: ApiConfig.tokenKey);

  Future<String?> readToken() => _storage.read(key: ApiConfig.tokenKey);

  static String _extract(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (e.type == DioExceptionType.connectionError) return 'Serveur injoignable.';
    return e.message ?? 'Erreur inconnue';
  }
}
