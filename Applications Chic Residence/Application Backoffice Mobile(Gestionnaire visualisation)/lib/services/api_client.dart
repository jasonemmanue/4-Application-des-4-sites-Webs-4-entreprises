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
        final code = e.response?.statusCode;
        if (code == 401) {
          onSessionExpired?.call();
        }
        final msg = _extract(e);
        handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: ApiException(msg, statusCode: code),
          response: e.response,
          type: e.type,
        ));
      },
    ));
  }

  /// Callback appele quand le serveur repond 401 (session expiree/revoquee).
  void Function()? onSessionExpired;

  final Dio dio;
  final _storage = const FlutterSecureStorage();

  Future<void> setToken(String token) =>
      _storage.write(key: ApiConfig.tokenKey, value: token);

  Future<void> clearToken() =>
      _storage.delete(key: ApiConfig.tokenKey);

  Future<String?> readToken() => _storage.read(key: ApiConfig.tokenKey);

  static String _extract(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final raw = (data['detail'] ?? data['message'])?.toString();
      if (raw != null && raw.length < 200 && !_looksInternal(raw)) return raw;
    }

    if (code == 429) return 'Trop de tentatives. Reessayez dans quelques instants.';
    if (code == 401) return 'Session expiree. Reconnectez-vous.';
    if (code == 403) return 'Acces refuse.';
    if (code != null && code >= 500) return 'Erreur serveur. Reessayez plus tard.';

    if (e.type == DioExceptionType.connectionError) return 'Serveur injoignable.';
    return 'Une erreur est survenue.';
  }

  static bool _looksInternal(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('traceback') ||
        lower.contains('stacktrace') ||
        lower.contains('internal server') ||
        lower.contains('sqlalchemy') ||
        lower.contains('postgres') ||
        lower.contains('redis') ||
        lower.contains('file "');
  }
}
