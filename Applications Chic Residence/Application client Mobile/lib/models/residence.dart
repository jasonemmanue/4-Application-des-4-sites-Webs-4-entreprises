enum ResidenceType { studio, appartement, villa, duplex, chambre }

extension ResidenceTypeX on ResidenceType {
  String get label {
    switch (this) {
      case ResidenceType.studio:
        return 'Studio';
      case ResidenceType.appartement:
        return 'Appartement';
      case ResidenceType.villa:
        return 'Villa';
      case ResidenceType.duplex:
        return 'Duplex';
      case ResidenceType.chambre:
        return 'Chambre';
    }
  }

  /// Valeur attendue par l'API — **anglaise**, et différente du nom Dart pour
  /// deux cas.
  ///
  /// Le backend déclare `Enum("studio", "apartment", "villa", "duplex",
  /// "room", name="residence_type")`. Envoyer `appartement` ou `chambre`
  /// produit une **erreur 500** (l'enum PostgreSQL refuse la valeur), pas un
  /// 422 : le filtre paraissait donc « casser l'API » alors qu'il envoyait
  /// simplement un mot français.
  String get apiValue {
    switch (this) {
      case ResidenceType.studio:
        return 'studio';
      case ResidenceType.appartement:
        return 'apartment';
      case ResidenceType.villa:
        return 'villa';
      case ResidenceType.duplex:
        return 'duplex';
      case ResidenceType.chambre:
        return 'room';
    }
  }

  /// Accepte la valeur API (anglaise) comme le nom Dart (français) : les
  /// réponses du backend portent la première, d'anciens caches locaux la
  /// seconde.
  static ResidenceType parse(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'studio':
        return ResidenceType.studio;
      case 'apartment':
      case 'appartement':
        return ResidenceType.appartement;
      case 'villa':
        return ResidenceType.villa;
      case 'duplex':
        return ResidenceType.duplex;
      case 'room':
      case 'chambre':
        return ResidenceType.chambre;
      default:
        return ResidenceType.appartement;
    }
  }
}

enum AvailabilityStatus { available, occupied, maintenance }

extension AvailabilityStatusX on AvailabilityStatus {
  String get label {
    switch (this) {
      case AvailabilityStatus.available:
        return 'Libre';
      case AvailabilityStatus.occupied:
        return 'Occupe';
      case AvailabilityStatus.maintenance:
        return 'Maintenance';
    }
  }

  static AvailabilityStatus parse(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'occupied':
      case 'occupe':
        return AvailabilityStatus.occupied;
      case 'maintenance':
        return AvailabilityStatus.maintenance;
      default:
        return AvailabilityStatus.available;
    }
  }
}

/// Modele residence — aligne sur le schema ResidenceOut du backend FastAPI.
///
/// Note : les IDs sont des UUID (string), pas des int. Les montants sont
/// serialises en string cote API pour eviter la perte de precision JSON —
/// on les reparse ici en int (FCFA sans decimales).
class Residence {
  final String id;
  final String slug;
  final String name; // API: title
  final ResidenceType type; // API: residence_type
  final String city;
  final String? country;
  final String address;
  final int capacity;
  final int bedrooms;
  final int bathrooms;
  final int? areaSqm;
  final int pricePerNight; // API: base_price_per_night (string parsee)
  final double rating;
  final int reviewsCount;
  final AvailabilityStatus availability; // API: availability_status
  final String description;
  final List<String> photos; // API: images
  final List<String> amenities;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final bool isFeatured;

  const Residence({
    required this.id,
    required this.slug,
    required this.name,
    required this.type,
    required this.city,
    this.country,
    required this.address,
    required this.capacity,
    required this.bedrooms,
    required this.bathrooms,
    this.areaSqm,
    required this.pricePerNight,
    required this.rating,
    required this.reviewsCount,
    required this.availability,
    required this.description,
    required this.photos,
    required this.amenities,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.isFeatured = false,
  });

  String get mainPhoto => photos.isNotEmpty
      ? photos.first
      : 'https://placehold.co/800x600/EF4444/FFFFFF?text=Chic+Residence';

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(',', '.').split('.').first) ??
        fallback;
  }

  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? fallback;
  }

  factory Residence.fromJson(Map<String, dynamic> json) => Residence(
        id: json['id']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        name: (json['title'] ?? json['name'])?.toString() ?? '',
        type: ResidenceTypeX.parse(
            (json['residence_type'] ?? json['type'])?.toString()),
        city: json['city']?.toString() ?? 'Abidjan',
        country: json['country']?.toString(),
        address: json['address']?.toString() ?? '',
        capacity: _toInt(json['capacity'], 2),
        bedrooms: _toInt(json['bedrooms'], 1),
        bathrooms: _toInt(json['bathrooms'], 1),
        areaSqm: json['area_sqm'] == null ? null : _toInt(json['area_sqm']),
        pricePerNight: _toInt(
            json['base_price_per_night'] ?? json['price_per_night'], 0),
        rating: _toDouble(json['rating'] ?? json['average_rating']),
        reviewsCount: _toInt(json['reviews_count'] ?? json['review_count']),
        availability: AvailabilityStatusX.parse(
            (json['availability_status'] ?? json['availability'])?.toString()),
        description: json['description']?.toString() ?? '',
        photos: (json['images'] as List?)
                ?.map((e) => e is Map ? (e['url']?.toString() ?? '') : e.toString())
                .where((s) => s.isNotEmpty)
                .toList() ??
            (json['photos'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        amenities:
            (json['amenities'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isActive: json['is_active'] != false,
        isFeatured: json['is_featured'] == true,
      );
}
