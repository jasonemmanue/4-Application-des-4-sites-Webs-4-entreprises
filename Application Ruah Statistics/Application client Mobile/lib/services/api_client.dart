import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/article.dart';
import '../models/contact_message.dart';
import '../models/key_figure.dart';
import '../models/lead.dart';
import '../models/partner.dart';
import '../models/project.dart';
import '../models/service.dart';
import '../models/team_member.dart';
import '../models/testimonial.dart';
import '../models/video.dart';
import 'network.dart';

class PagedResult<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final int total;

  const PagedResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio;

  ApiClient([Dio? dio]) : _dio = dio ?? _build();

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'X-Client-Source': 'android',
      },
      responseType: ResponseType.json,
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        request: false,
        requestBody: false,
        responseBody: false,
        error: true,
      ));
    }

    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: ApiException(
            _extractMessage(e),
            statusCode: e.response?.statusCode,
          ),
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

    if (data is Map) {
      final raw = (data['detail'] ?? data['message'])?.toString();
      if (raw != null && raw.length < 200 && !_looksInternal(raw)) return raw;
    }

    if (code == 429) return 'Trop de requêtes. Réessayez dans quelques instants.';
    if (code == 401) return 'Session expirée.';
    if (code == 403) return 'Accès refusé.';
    if (code == 404) return 'Ressource introuvable.';
    if (code == 422) return 'Données invalides. Vérifiez votre saisie.';
    if (code != null && code >= 500) return 'Erreur serveur. Réessayez plus tard.';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Délai dépassé. Vérifiez votre connexion.';
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

  // ---------------------------------------------------------------
  // GET
  // ---------------------------------------------------------------

  Future<List<Service>> fetchServices() async {
    final data = await _getList('/services');
    return data
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Service> fetchServiceBySlug(String slug) async {
    final data = await _getMap('/services/$slug');
    return Service.fromJson(data);
  }

  Future<PagedResult<Project>> fetchProjects({
    int page = 1,
    String? sector,
    String? country,
    int? year,
  }) async {
    final data = await _getMap(
      '/projects',
      query: {
        'page': page,
        if (sector != null) 'sector': sector,
        if (country != null) 'country': country,
        if (year != null) 'year': year,
      },
    );
    return _extractPage(data, Project.fromJson);
  }

  Future<Project> fetchProjectBySlug(String slug) async {
    final data = await _getMap('/projects/$slug');
    return Project.fromJson(data);
  }

  Future<List<TeamMember>> fetchTeam() async {
    final data = await _getList('/team');
    return data
        .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeamMember?> fetchTeamMember(String id) async {
    final all = await fetchTeam();
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<PagedResult<Article>> fetchArticles({
    int page = 1,
    ArticleType? type,
  }) async {
    final data = await _getMap(
      '/articles',
      query: {
        'page': page,
        if (type == ArticleType.whitepaper) 'type': 'whitepaper',
        if (type == ArticleType.article) 'type': 'article',
      },
    );
    return _extractPage(data, Article.fromJson);
  }

  Future<Article> fetchArticleBySlug(String slug) async {
    final data = await _getMap('/articles/$slug');
    return Article.fromJson(data);
  }

  Future<List<Video>> fetchVideos() async {
    final data = await _getList('/videos');
    return data.map((e) => Video.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Testimonial>> fetchTestimonials() async {
    final data = await _getList('/testimonials');
    return data
        .map((e) => Testimonial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Partner>> fetchPartners() async {
    final data = await _getList('/partners');
    return data
        .map((e) => Partner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<KeyFigure>> fetchKeyFigures() async {
    final data = await _getList('/key-figures');
    return data
        .map((e) => KeyFigure.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------
  // POST
  // ---------------------------------------------------------------

  Future<Map<String, dynamic>> requestWhitepaperDownload({
    required String articleId,
    required String whatsappNumber,
    String? fullName,
    String? company,
  }) async {
    final resp = await _dio.post(
      '/articles/$articleId/download',
      data: {
        'whatsapp_number': whatsappNumber,
        if (fullName != null) 'name': fullName,
        if (company != null) 'company': company,
      },
    );
    return _asMap(resp.data);
  }

  Future<void> submitTestimonial(TestimonialSubmission submission) async {
    await _dio.post('/testimonials/submit', data: submission.toJson());
  }

  Future<Map<String, dynamic>> submitQuoteRequest(QuoteLead lead) async {
    final resp = await _dio.post('/leads/quote-request', data: lead.toJson());
    return _asMap(resp.data);
  }

  Future<Map<String, dynamic>> submitContactMessage(
      ContactMessage message) async {
    final resp = await _dio.post('/contact', data: message.toJson());
    return _asMap(resp.data);
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

  Future<List> _getList(String path, {Map<String, dynamic>? query}) async {
    final resp = await _dio.get(path, queryParameters: query);
    final data = resp.data;
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  Future<Map<String, dynamic>> _getMap(String path,
      {Map<String, dynamic>? query}) async {
    final resp = await _dio.get(path, queryParameters: query);
    return _asMap(resp.data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Reponse invalide du serveur');
  }

  PagedResult<T> _extractPage<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List raw = (data['items'] as List?) ??
        (data['data'] as List?) ??
        (data['results'] as List?) ??
        const [];
    return PagedResult<T>(
      items: raw.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      page: (data['page'] as int?) ?? 1,
      totalPages:
          (data['total_pages'] as int?) ?? (data['pages'] as int?) ?? 1,
      total: (data['total'] as int?) ?? raw.length,
    );
  }
}
