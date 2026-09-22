import '../config/api_config.dart';

class Service {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? methodology;
  final List<String> sectors;
  final List<String> deliverables;
  final String? icon;
  final String? imageUrl;
  final int? order;
  final bool isActive;

  const Service({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.methodology,
    this.sectors = const [],
    this.deliverables = const [],
    this.icon,
    this.imageUrl,
    this.order,
    this.isActive = true,
  });

  String? get summary => description;
  String? get coverImage => ApiConfig.resolveMediaUrl(imageUrl);

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: (json['id'] ?? '').toString(),
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      methodology: json['methodology'] as String?,
      sectors: (json['sectors'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      deliverables:
          (json['deliverables'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      icon: json['icon'] as String?,
      imageUrl: json['image_url'] as String?,
      order: json['order'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
