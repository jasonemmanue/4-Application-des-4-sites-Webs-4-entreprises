import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'network.dart';

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
    // En premier : une lecture coupée par le réseau est retentée avant que
    // l'erreur ne soit traduite pour l'écran.
    dio.interceptors.insert(0, RetryOnNetwork(dio));

    return dio;
  }

  static String _extractMessage(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    // Messages metier du serveur (detail/message) : on les affiche
    // seulement s'ils ne contiennent pas de trace technique.
    if (data is Map) {
      final raw = (data['detail'] ?? data['message'])?.toString();
      if (raw != null && raw.length < 200 && !_looksInternal(raw)) return raw;
    }

    if (code == 429) return 'Trop de tentatives. Reessayez dans quelques instants.';
    if (code == 401) return 'Session expiree. Reconnectez-vous.';
    if (code == 403) return 'Acces refuse.';
    if (code == 404) return 'Ressource introuvable.';
    if (code != null && code >= 500) return 'Erreur serveur. Reessayez plus tard.';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Delai depasse. Verifiez votre connexion.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur.';
    }
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
