import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../models/article.dart';
import '../models/booking.dart';
import '../models/category.dart';
import '../models/gallery_item.dart';
import '../models/quote_request.dart';
import '../models/review.dart';
import '../models/service.dart';
import '../models/team_member.dart';
import '../models/video.dart';

/// Client HTTP unique de l'application mobile.
///
/// Il consomme **la même API FastAPI que le site web** — celle du dépôt
/// `salon-coiffure/backend/` (base `/api/v1`), déployée sur Railway pour la
/// production. Il n'y a pas d'API dédiée à l'application : mêmes routes, même
/// base de données, même administration Next.js.
///
/// Base URL configurée par [ApiConfig.baseUrl] et surchargeable au build via
/// `--dart-define=API_BASE_URL=…`.
class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.apiRoot,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: <String, dynamic>{
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  // Origine de la requête, lue côté backend par
                  // `get_client_source` puis stockée sur la réservation,
                  // l'avis, le contact ou le devis — pour distinguer, dans
                  // l'administration, une demande venue de l'application
                  // Android d'une demande venue du site web (qui n'envoie
                  // pas cet en-tête). Version alignée sur pubspec.yaml.
                  'X-App-Source': ApiConfig.appSource,
                },
              ),
            );

  final Dio _dio;
  Dio get dio => _dio;

  // ─── Helpers ────────────────────────────────────────────────────────────

  Future<Response<dynamic>> _get(String path,
      {Map<String, dynamic>? query}) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<Response<dynamic>> _post(String path,
      {dynamic data, FormData? form}) async {
    try {
      return await _dio.post(
        path,
        data: form ?? data,
        options: form != null
            ? Options(contentType: 'multipart/form-data')
            : null,
      );
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  ApiException _wrap(DioException e) {
    // L'API renvoie systématiquement { detail: "…" } sur 4xx/5xx (convention
    // FastAPI). On l'extrait pour afficher un message utile à la cliente ;
    // sinon, on retombe sur le message technique de Dio.
    final data = e.response?.data;
    String message = e.message ?? 'Erreur réseau';
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        // Erreur de validation Pydantic : liste d'objets { loc, msg, type }.
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          message = first['msg'] as String;
        }
      }
    }
    return ApiException(message, e.response?.statusCode);
  }

  List<T> _asList<T>(Response<dynamic> res, T Function(Map<String, dynamic>) f) {
    final body = res.data;
    Iterable items;
    if (body is List) {
      items = body;
    } else if (body is Map<String, dynamic>) {
      items = (body['items'] ?? body['data'] ?? body['results'] ?? const [])
          as Iterable;
    } else {
      items = const [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(f)
        .toList(growable: false);
  }

  // ─── Catalogue : services et catégories ─────────────────────────────────

  /// `GET /services` — filtrable par slug de catégorie côté serveur.
  ///
  /// L'API accepte `?category=<slug>` ; on n'a donc pas à recharger toutes
  /// les prestations puis à filtrer localement (l'ancien code faisait
  /// deux allers-retours pour rien).
  Future<List<Service>> fetchServices({String? categorySlug}) async {
    final res = await _get(
      '/services',
      query: categorySlug != null && categorySlug.isNotEmpty
          ? <String, dynamic>{'category': categorySlug}
          : null,
    );
    return _asList(res, Service.fromJson);
  }

  /// `GET /services/{slug}` — route exposée par le backend depuis 2026-08.
  Future<Service> fetchServiceBySlug(String slug) async {
    final res = await _get('/services/$slug');
    return Service.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Category>> fetchCategories() async {
    final res = await _get('/categories');
    return _asList(res, Category.fromJson);
  }

  // ─── Équipe ─────────────────────────────────────────────────────────────

  Future<List<TeamMember>> fetchTeam() async {
    final res = await _get('/team');
    return _asList(res, TeamMember.fromJson);
  }

  Future<TeamMember> fetchTeamMember(String id) async {
    final res = await _get('/team/$id');
    return TeamMember.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Réservation ────────────────────────────────────────────────────────

  /// `GET /bookings/available-slots?service_id=&team_member_id=&date=`
  ///
  /// L'API renvoie **tous** les créneaux du salon avec un drapeau
  /// `available`. On ne remonte à l'écran que ceux qui sont libres.
  Future<List<String>> fetchAvailableSlots({
    required String serviceId,
    required String teamMemberId,
    required DateTime date,
  }) async {
    final res = await _get('/bookings/available-slots', query: <String, dynamic>{
      'service_id': serviceId,
      'team_member_id': teamMemberId,
      'date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    });
    final body = res.data;
    if (body is! List) return const <String>[];
    return body
        .whereType<Map<String, dynamic>>()
        .where((slot) => (slot['available'] as bool?) ?? false)
        .map((slot) => slot['time']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  /// `POST /bookings`
  Future<Booking> createBooking(Booking booking) async {
    final res = await _post('/bookings', data: booking.toCreateJson());
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  /// `POST /bookings/{id}/cancel` — route publique : la cliente annule
  /// elle-même son rendez-vous tant que l'acompte n'a pas été encaissé.
  Future<Booking> cancelBooking(String bookingId) async {
    final res = await _post('/bookings/$bookingId/cancel');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Galerie, articles, vidéos ──────────────────────────────────────────

  Future<List<GalleryItem>> fetchGallery() async {
    final res = await _get('/gallery');
    return _asList(res, GalleryItem.fromJson);
  }

  Future<List<Article>> fetchArticles({int page = 1, int perPage = 20}) async {
    final res = await _get('/articles', query: <String, dynamic>{
      'page': page,
      'per_page': perPage,
    });
    return _asList(res, Article.fromJson);
  }

  Future<Article> fetchArticleBySlug(String slug) async {
    final res = await _get('/articles/$slug');
    return Article.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Video>> fetchVideos() async {
    final res = await _get('/videos');
    return _asList(res, Video.fromJson);
  }

  // ─── Avis ───────────────────────────────────────────────────────────────

  Future<List<Review>> fetchReviews() async {
    final res = await _get('/reviews');
    return _asList(res, Review.fromJson);
  }

  /// `POST /reviews` — le backend borne `rating` à 1..5 (422 sinon).
  Future<void> submitReview(ReviewSubmission review) async {
    await _post('/reviews', data: review.toJson());
  }

  // ─── Contact et devis ──────────────────────────────────────────────────

  /// `POST /contact` — schéma `ContactCreate` du backend :
  /// { name, email, phone, subject, message }.
  Future<void> sendContactMessage({
    required String name,
    required String phone,
    String? email,
    String? subject,
    required String message,
  }) async {
    await _post('/contact', data: <String, dynamic>{
      'name': name,
      'phone': phone,
      'email': email ?? '',
      'subject': subject ?? '',
      'message': message,
    });
  }

  /// `POST /quotes` — multipart. Le backend attend :
  /// `client_name`, `hairstyle_name`, `image` (fichier), plus `client_email`,
  /// `client_phone`, `message` en champs facultatifs.
  Future<void> submitQuoteRequest(QuoteRequest req) async {
    if (req.photo == null) {
      throw ApiException(
          'Une photo est obligatoire pour envoyer une demande de devis.', 400);
    }
    final form = FormData.fromMap(<String, dynamic>{
      'client_name': req.customerName,
      'client_phone': req.customerPhone,
      if (req.customerEmail != null && req.customerEmail!.isNotEmpty)
        'client_email': req.customerEmail,
      'hairstyle_name': req.description,
      'message': req.description,
      'image': await MultipartFile.fromFile(
        req.photo!.path,
        filename: req.photo!.uri.pathSegments.last,
      ),
    });
    await _post('/quotes', form: form);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
