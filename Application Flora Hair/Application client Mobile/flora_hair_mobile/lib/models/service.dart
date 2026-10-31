enum ServicePriceType { fixed, range, startingAt }

String _thousands(int amount) {
  final s = amount.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

/// `15000` → `15 000 FCFA`. Le franc CFA n'a pas de subdivision.
String formatFcfa(num amount) => '${_thousands(amount.toInt())} FCFA';

class Service {
  const Service({
    required this.id,
    required this.slug,
    required this.name,
    required this.categoryId,
    required this.priceMin,
    this.priceMax,
    this.priceFrom = false,
    required this.durationMinutes,
    this.description,
    this.imageUrl,
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String slug;
  final String name;
  final String categoryId;
  final int priceMin;
  final int? priceMax;
  final bool priceFrom;
  final int durationMinutes;
  final String? description;
  final String? imageUrl;
  final int order;
  final bool isActive;

  ServicePriceType get priceType {
    if (priceMax != null && priceMax! > priceMin) return ServicePriceType.range;
    if (priceFrom) return ServicePriceType.startingAt;
    return ServicePriceType.fixed;
  }

  int get depositAmount => (priceMin * 0.5).round();

  /// `60 min`, `2 h`, `1 h 30`.
  String get formattedDuration {
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
  }

  /// Prix court des vignettes : `dès 5 000 FCFA`, ou le prix exact s'il est fixe.
  String get shortPrice => priceType == ServicePriceType.fixed
      ? formatFcfa(priceMin)
      : 'dès ${formatFcfa(priceMin)}';

  String formattedPrice() {
    switch (priceType) {
      case ServicePriceType.fixed:
        return formatFcfa(priceMin);
      case ServicePriceType.range:
        return '${_thousands(priceMin)} – ${formatFcfa(priceMax!)}';
      case ServicePriceType.startingAt:
        return 'À partir de ${formatFcfa(priceMin)}';
    }
  }

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'].toString(),
        slug: json['slug'] as String,
        name: json['name'] as String,
        categoryId: (json['category_id'] ?? '').toString(),
        priceMin: (json['price'] as num?)?.toInt() ??
            (json['price_min'] as num?)?.toInt() ??
            0,
        priceMax: (json['price_max'] as num?)?.toInt(),
        priceFrom: (json['price_from'] as bool?) ?? false,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        order: (json['order'] as num?)?.toInt() ?? 0,
        isActive: (json['is_active'] as bool?) ?? true,
      );
}
