/// Client HTTP unique pour l'API FastAPI du site salle-de-sport.
///
/// Regles :
///   * Aucun montant n'est envoye au serveur — le backend recalcule l'acompte
///     depuis la formule (voir `PaymentInitRequest` cote FastAPI).
///   * Les listes paginees renvoient `{items,total,page,pages}` : `_asList`
///     accepte les deux formes (liste brute et enveloppe paginee).
///   * `/settings/public` renvoie `list[{key,value}]` — on l'aplatit ici en
///     `Map<String,String>` avant de construire `PublicSettings`.
///   * Les paths sensibles alignes sur le backend :
///       - `/enrollments/slot/{id}/availability` (singulier).
///       - `/activities/{slug}` (jamais parcourir la liste).
///       - `/subscriptions/orders` (sans slash final).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/activity.dart';
import '../models/article.dart';
import '../models/coach.dart';
import '../models/enrollment.dart';
import '../models/equipment.dart';
import '../models/payment.dart';
import '../models/public_settings.dart';
import '../models/review.dart';
import '../models/schedule_slot.dart';
import '../models/subscription.dart';
import '../models/transformation.dart';
import '../models/video.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;

  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
  bool get isServerDown => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient([Dio? dio]) : _dio = dio ?? _buildDio();

  final Dio _dio;
  Dio get dio => _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBase,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          // Lu par le backend (`get_client_source`) pour distinguer les
          // creations issues de l'app mobile de celles issues du site web
          // dans le back-office. Valeurs acceptees : `web` | `mobile`.
          'X-Client-Source': 'mobile',
        },
        responseType: ResponseType.json,
        followRedirects: true,
        // On laisse remonter les 4xx pour les traiter uniformement dans `_wrap`.
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    return dio;
  }

  // ─────────────────────────── HTTP primitives ────────────────────────────

  Future<Response<dynamic>> _get(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get(path, queryParameters: _cleanQuery(query)));

  Future<Response<dynamic>> _post(String path, {Object? data}) =>
      _run(() => _dio.post(path, data: data));

  Future<Response<dynamic>> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final status = response.statusCode ?? 0;
      if (status >= 400) throw _fromResponse(response);
      return response;
    } on DioException catch (e) {
      throw _fromDioException(e);
    }
  }

  Map<String, dynamic>? _cleanQuery(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      out[k] = v;
    });
    return out.isEmpty ? null : out;
  }

  ApiException _fromResponse(Response<dynamic> r) {
    final code = r.statusCode ?? 0;
    return ApiException(
      _extractMessage(r.data, code),
      statusCode: code,
    );
  }

  ApiException _fromDioException(DioException e) {
    final status = e.response?.statusCode;
    if (status != null && e.response != null) {
      return ApiException(
        _extractMessage(e.response!.data, status),
        statusCode: status,
      );
    }
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Delai de connexion depasse. Reessayez.',
      DioExceptionType.connectionError =>
        'Impossible de joindre le serveur. Verifiez votre reseau.',
      DioExceptionType.badCertificate =>
        'Certificat serveur invalide.',
      _ => 'Une erreur reseau est survenue.',
    };
    return ApiException(message, statusCode: status);
  }

  String _extractMessage(dynamic data, int status) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return first['msg'] as String;
        }
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return switch (status) {
      400 => 'Requete invalide.',
      401 => 'Authentification requise.',
      403 => 'Acces refuse.',
      404 => 'Ressource introuvable.',
      409 => 'Conflit avec l\'etat actuel.',
      422 => 'Donnees invalides.',
      429 => 'Trop de requetes, patientez un instant.',
      _ => 'Erreur $status.',
    };
  }

  List<T> _asList<T>(dynamic data, T Function(Map<String, dynamic>) build) {
    List<dynamic>? raw;
    if (data is List) raw = data;
    if (data is Map<String, dynamic>) {
      raw = (data['items'] ?? data['results'] ?? data['data']) as List?;
    }
    if (raw == null) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(build)
        .toList(growable: false);
  }

  // ────────────────────────────── Activities ──────────────────────────────

  Future<List<Activity>> getActivities({
    int page = 1,
    int limit = 50,
    String? category,
    String? level,
  }) async {
    final r = await _get('/activities/', query: {
      'page': page,
      'limit': limit,
      'category': category,
      'level': level,
    });
    return _asList(r.data, Activity.fromJson);
  }

  Future<Activity?> getActivityBySlug(String slug) async {
    try {
      final r = await _get('/activities/$slug');
      final data = r.data;
      if (data is Map<String, dynamic>) return Activity.fromJson(data);
      return null;
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  // ─────────────────────────────── Schedule ───────────────────────────────

  Future<List<ScheduleSlot>> getSchedule({DateTime? day}) async {
    final r = await _get('/schedule/', query: {
      if (day != null) 'date': formatIso(day),
    });
    return _asList(r.data, ScheduleSlot.fromJson);
  }

  Future<Map<String, dynamic>> getWeeklySchedule() async {
    final r = await _get('/schedule/weekly');
    return (r.data is Map) ? (r.data as Map).cast<String, dynamic>() : const {};
  }

  // ──────────────────────────── Subscriptions ────────────────────────────

  Future<List<Subscription>> getSubscriptions() async {
    final r = await _get('/subscriptions/');
    return _asList(r.data, Subscription.fromJson);
  }

  Future<Map<String, dynamic>> createSubscriptionOrder({
    required String subscriptionId,
    required String userName,
    required String userWhatsapp,
    String? note,
  }) async {
    final r = await _post('/subscriptions/orders', data: {
      'subscription_id': subscriptionId,
      'user_name': userName,
      'user_whatsapp': userWhatsapp,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return (r.data as Map).cast<String, dynamic>();
  }

  // ─────────────────────────────── Coaches ───────────────────────────────

  Future<List<Coach>> getCoaches() async {
    final r = await _get('/coaches/');
    return _asList(r.data, Coach.fromJson);
  }

  Future<Coach?> getCoachById(String id) async {
    try {
      final r = await _get('/coaches/$id');
      final data = r.data;
      if (data is Map<String, dynamic>) return Coach.fromJson(data);
      return null;
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  // ────────────────────────────── Equipment ──────────────────────────────

  Future<List<Equipment>> getEquipment({String? zone}) async {
    final r = await _get('/equipment/', query: {'zone': zone});
    return _asList(r.data, Equipment.fromJson);
  }

  // ─────────────────────────────── Articles ──────────────────────────────

  Future<List<Article>> getArticles({int page = 1, int limit = 20}) async {
    final r = await _get('/articles/', query: {
      'page': page,
      'limit': limit,
    });
    return _asList(r.data, Article.fromJson);
  }

  Future<Article?> getArticleBySlug(String slug) async {
    try {
      final r = await _get('/articles/$slug');
      final data = r.data;
      if (data is Map<String, dynamic>) return Article.fromJson(data);
      return null;
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  // ──────────────────────────────── Videos ───────────────────────────────

  Future<List<Video>> getVideos({String? category}) async {
    final r = await _get('/videos/', query: {'category': category});
    return _asList(r.data, Video.fromJson);
  }

  // ─────────────────────────── Transformations ───────────────────────────

  Future<List<Transformation>> getTransformations({bool featuredOnly = false}) async {
    final r = await _get('/transformations/', query: {
      if (featuredOnly) 'featured_only': true,
    });
    return _asList(r.data, Transformation.fromJson);
  }

  // ─────────────────────────────── Reviews ───────────────────────────────

  Future<List<Review>> getReviews() async {
    final r = await _get('/reviews/');
    return _asList(r.data, Review.fromJson);
  }

  Future<void> submitReview({
    required String authorName,
    required int rating,
    String? comment,
  }) async {
    await _post('/reviews/', data: {
      'author_name': authorName,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  // ─────────────────────────────── Contact ───────────────────────────────

  Future<void> sendContact({
    required String name,
    required String whatsapp,
    required String subject,
    required String message,
  }) async {
    await _post('/contact/', data: {
      'name': name,
      'whatsapp': whatsapp,
      'subject': subject,
      'message': message,
    });
  }

  // ────────────────────────────── Settings ───────────────────────────────

  Future<PublicSettings> getPublicSettings() async {
    try {
      final r = await _get('/settings/public');
      final data = r.data;
      final map = <String, dynamic>{};
      if (data is List) {
        for (final entry in data) {
          if (entry is Map) {
            final key = entry['key']?.toString();
            final value = entry['value'];
            if (key != null && key.isNotEmpty) {
              map[key] = value;
            }
          }
        }
      } else if (data is Map<String, dynamic>) {
        map.addAll(data);
      }
      return PublicSettings.fromJson(map);
    } on ApiException {
      return const PublicSettings(gymName: ApiConfig.gymName);
    }
  }

  // ───────────────────────────── Enrollments ─────────────────────────────

  Future<Enrollment> createEnrollment(EnrollmentRequest req) async {
    final r = await _post('/enrollments/', data: req.toJson());
    return Enrollment.fromJson(r.data as Map<String, dynamic>);
  }

  /// Disponibilite d'un creneau pour une date donnee. Le backend expose
  /// `/enrollments/slot/{id}/availability` (singulier).
  Future<Map<String, dynamic>> getSlotAvailability(
    String slotId, {
    DateTime? specificDate,
  }) async {
    final r = await _get(
      '/enrollments/slot/$slotId/availability',
      query: {
        if (specificDate != null) 'specific_date': formatIso(specificDate),
      },
    );
    if (r.data is Map) return (r.data as Map).cast<String, dynamic>();
    return const {};
  }

  // ─────────────────────────────── Payments ──────────────────────────────

  Future<Map<String, dynamic>> getPaymentConfig() async {
    final r = await _get('/payments/config');
    return (r.data as Map).cast<String, dynamic>();
  }

  Future<PaymentInit> initPayment({
    String? enrollmentId,
    String? subscriptionOrderId,
    required PaymentOperator operator,
    required String paymentPhone,
  }) async {
    assert(
      (enrollmentId == null) != (subscriptionOrderId == null),
      'Fournir exactement un objet a regler (enrollment_id XOR subscription_order_id).',
    );
    final r = await _post('/payments/init', data: {
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (subscriptionOrderId != null)
        'subscription_order_id': subscriptionOrderId,
      'method': operator.code,
      if (paymentPhone.isNotEmpty) 'payment_phone': paymentPhone,
    });
    return PaymentInit.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PaymentStatusResponse> getPaymentStatus(String reference) async {
    final r = await _get('/payments/$reference');
    return PaymentStatusResponse.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PaymentStatusResponse> cancelPayment(String reference) async {
    final r = await _post('/payments/$reference/cancel');
    return PaymentStatusResponse.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PaymentStatusResponse> resendPush(String reference) async {
    final r = await _post('/payments/$reference/push/resend');
    return PaymentStatusResponse.fromJson(r.data as Map<String, dynamic>);
  }

  // ─────────────────────────────── Health ────────────────────────────────

  Future<bool> ping() async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiConfig.baseUrl}/health',
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      return data is Map && data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }
}

String formatIso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
