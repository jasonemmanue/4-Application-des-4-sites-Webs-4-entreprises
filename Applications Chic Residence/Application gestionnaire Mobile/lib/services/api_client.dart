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

  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

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
