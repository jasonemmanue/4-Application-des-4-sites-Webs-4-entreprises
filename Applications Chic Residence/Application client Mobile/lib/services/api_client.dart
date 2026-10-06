import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Client HTTP partage. Attache l'entete `X-Session-Id` pour les favoris
/// et intercepte les erreurs.
class ApiClient {
  ApiClient({String? sessionId}) : _dio = _build(sessionId);

  final Dio _dio;

  Dio get dio => _dio;

  static Dio _build(String? sessionId) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBase,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (sessionId != null) 'X-Session-Id': sessionId,
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        // Normaliser les erreurs API en ApiException
        final msg = _extractMessage(e);
        handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: ApiException(msg, statusCode: e.response?.statusCode),
          response: e.response,
          type: e.type,
        ));
      },
    ));

    return dio;
  }

  static String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Delai depasse. Verifiez votre connexion.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur.';
    }
    return e.message ?? 'Une erreur est survenue.';
  }

  void updateSessionId(String sessionId) {
    _dio.options.headers['X-Session-Id'] = sessionId;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
