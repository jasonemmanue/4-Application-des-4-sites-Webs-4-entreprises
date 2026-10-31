import '../models/residence.dart';
import '../models/other_models.dart';
import 'api_client.dart';

class ResidenceFilters {
  final String? query;
  final ResidenceType? type;
  final String? city;
  final int? capacity;
  final int? priceMin;
  final int? priceMax;
  final List<String> amenities;
  final String? sort;
  final int page;

  const ResidenceFilters({
    this.query,
    this.type,
    this.city,
    this.capacity,
    this.priceMin,
    this.priceMax,
    this.amenities = const [],
    this.sort,
    this.page = 1,
  });

  Map<String, dynamic> toQuery() => {
        // Plafond de l'API. Par défaut elle n'en renvoie que 12 sur 21 logements.
        'limit': 100,
        if (query != null && query!.isNotEmpty) 'search': query,
        if (type != null) 'residence_type': type!.apiValue,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (capacity != null) 'capacity_min': capacity,
        if (priceMin != null) 'price_min': priceMin,
        if (priceMax != null) 'price_max': priceMax,
        if (amenities.isNotEmpty) 'amenities': amenities,
        if (sort != null) 'sort': sort,
        'page': page,
      };

  ResidenceFilters copyWith({
    String? query,
    ResidenceType? type,
    bool clearType = false,
    String? city,
    bool clearCity = false,
    int? capacity,
    bool clearCapacity = false,
    int? priceMin,
    int? priceMax,
    List<String>? amenities,
    String? sort,
    int? page,
  }) =>
      ResidenceFilters(
        query: query ?? this.query,
        type: clearType ? null : (type ?? this.type),
        city: clearCity ? null : (city ?? this.city),
        capacity: clearCapacity ? null : (capacity ?? this.capacity),
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        amenities: amenities ?? this.amenities,
        sort: sort ?? this.sort,
        page: page ?? this.page,
      );
}

class ResidenceService {
  ResidenceService(this._api);
  final ApiClient _api;

  Future<List<Residence>> list([ResidenceFilters? f]) async {
    final res = await _api.dio.get(
      '/residences',
      queryParameters: (f ?? const ResidenceFilters()).toQuery(),
    );
    final data = res.data;
    final items = (data is Map ? data['items'] : data) as List? ?? [];
    return items
        .map((e) => Residence.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Residence> detail(String idOrSlug) async {
    final res = await _api.dio.get('/residences/$idOrSlug');
    return Residence.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  Future<List<String>> suggestions(String q) async {
    if (q.trim().isEmpty) return const [];
    final res = await _api.dio
        .get('/residences/suggestions', queryParameters: {'q': q.trim()});
    final data = res.data;
    final items = (data is Map ? data['items'] : data) as List? ?? [];
    return items
        .map((e) => e is Map ? (e['label'] ?? e['title'] ?? '').toString() : e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<List<AvailabilityDay>> availability(
      String residenceId, int month, int year) async {
    // Le backend attend `month=YYYY-MM` (un seul paramètre), pas month+year.
    final mm = month.toString().padLeft(2, '0');
    final res = await _api.dio.get(
      '/availability/$residenceId',
      queryParameters: {'month': '$year-$mm'},
    );
    final data = res.data;
    final items = (data is Map ? data['days'] ?? data['items'] : data) as List? ?? [];
    return items
        .map((e) =>
            AvailabilityDay.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<AvailabilityDay>> availabilityRange(
      String residenceId, DateTime start, DateTime end) async {
    final res = await _api.dio.get(
      '/availability/$residenceId',
      queryParameters: {
        'start': start.toIso8601String().substring(0, 10),
        'end': end.toIso8601String().substring(0, 10),
      },
    );
    final data = res.data;
    final items = (data is Map ? data['days'] ?? data['items'] : data) as List? ?? [];
    return items
        .map((e) =>
            AvailabilityDay.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// L'avis part en modération : il n'apparaît qu'une fois approuvé dans
  /// l'administration (web ou backoffice mobile).
  Future<void> submitReview({
    required String residenceId,
    required String author,
    required int rating,
    required String comment,
  }) async {
    await _api.dio.post('/reviews', data: {
      'residence_id': residenceId,
      'author_name': author,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<Review>> reviews(String residenceId) async {
    // Le backend renvoie un PaginatedResponse{items,total,page,limit,total_pages}
    final res = await _api.dio
        .get('/reviews', queryParameters: {'residence_id': residenceId});
    final data = res.data;
    final items = (data is Map ? data['items'] : data) as List? ?? [];
    return items
        .map((e) => Review.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Avis récents (toutes résidences) — alimente le carrousel « Avis de nos
  /// voyageurs » de l'accueil, comme le fait la page d'accueil du site web.
  Future<List<Review>> topReviews({int limit = 12}) async {
    final res =
        await _api.dio.get('/reviews', queryParameters: {'limit': limit});
    final data = res.data;
    final items = (data is Map ? data['items'] : data) as List? ?? [];
    return items
        .map((e) => Review.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
