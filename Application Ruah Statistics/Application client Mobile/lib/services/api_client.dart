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
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final Dio _dio;

  ApiClient([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: {
                'Accept': 'application/json',
                // Permet a l'admin de distinguer les soumissions mobiles des
                // soumissions site web. Le backend lit ce header et le stocke
                // dans la colonne `source`. Absence de header = "website"
                // (defaut cote backend), donc pas de casse pour le site.
                'X-Client-Source': 'android',
              },
              responseType: ResponseType.json,
            )) {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: false,
        requestBody: false,
        responseBody: false,
        error: true,
      ));
    }
  }

  Future<List<Service>> fetchServices() async {
    final data = await _get<List>('/services');
    return data
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Service> fetchServiceBySlug(String slug) async {
    final data = await _get<Map<String, dynamic>>('/services/$slug');
    return Service.fromJson(data);
  }

  Future<PagedResult<Project>> fetchProjects({
    int page = 1,
    String? sector,
    String? country,
    int? year,
  }) async {
    final data = await _get<Map<String, dynamic>>(
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
    final data = await _get<Map<String, dynamic>>('/projects/$slug');
    return Project.fromJson(data);
  }

  Future<List<TeamMember>> fetchTeam() async {
    final data = await _get<List>('/team');
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
    final data = await _get<Map<String, dynamic>>(
      '/articles',
      query: {
        'page': page,
        if (type == ArticleType.whitepaper) 'article_type': 'whitepaper',
        if (type == ArticleType.article) 'article_type': 'article',
      },
    );
    return _extractPage(data, Article.fromJson);
  }

  Future<Article> fetchArticleBySlug(String slug) async {
    final data = await _get<Map<String, dynamic>>('/articles/$slug');
    return Article.fromJson(data);
  }

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

  Future<List<Video>> fetchVideos() async {
    final data = await _get<List>('/videos');
    return data.map((e) => Video.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Testimonial>> fetchTestimonials() async {
    final data = await _get<List>('/testimonials');
    return data
        .map((e) => Testimonial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitTestimonial(TestimonialSubmission submission) async {
    await _dio.post('/testimonials/submit', data: submission.toJson());
  }

  Future<List<Partner>> fetchPartners() async {
    final data = await _get<List>('/partners');
    return data
        .map((e) => Partner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<KeyFigure>> fetchKeyFigures() async {
    final data = await _get<List>('/key-figures');
    return data
        .map((e) => KeyFigure.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<T> _get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      final resp = await _dio.get(path, queryParameters: query);
      final data = resp.data;
      if (T == List) {
        if (data is List) return data as T;
        if (data is Map && data['items'] is List) return data['items'] as T;
        if (data is Map && data['data'] is List) return data['data'] as T;
      }
      if (T == Map<String, dynamic>) {
        return _asMap(data) as T;
      }
      return data as T;
    } on DioException catch (e) {
      throw ApiException(
        _errorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
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
      totalPages: (data['total_pages'] as int?) ??
          (data['pages'] as int?) ??
          1,
      total: (data['total'] as int?) ?? raw.length,
    );
  }

  String _errorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Delai depasse. Verifiez votre connexion.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de contacter le serveur.';
    }
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    if (data is Map && data['detail'] is List) {
      final errs = (data['detail'] as List)
          .map((e) => e is Map ? (e['msg'] ?? '').toString() : e.toString())
          .where((s) => s.isNotEmpty)
          .join(' ; ');
      if (errs.isNotEmpty) return errs;
    }
    if (data is Map && data['message'] is String) return data['message'] as String;
    return e.message ?? 'Erreur inconnue';
  }
}
