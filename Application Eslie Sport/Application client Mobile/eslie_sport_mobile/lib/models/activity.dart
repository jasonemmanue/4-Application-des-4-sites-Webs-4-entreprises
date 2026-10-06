import '../config/api_config.dart';

class Activity {
  final String id;
  final String slug;
  final String name;
  final String description;
  final String category;
  final String level;
  final int durationMinutes;
  final int maxCapacity;
  final String? imageUrl;
  final bool isActive;
  final int order;

  const Activity({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.category,
    required this.level,
    required this.durationMinutes,
    required this.maxCapacity,
    this.imageUrl,
    this.isActive = true,
    this.order = 0,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'].toString(),
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        level: json['level'] as String? ?? '',
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
        maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 0,
        imageUrl: ApiConfig.resolveMediaUrl(json['image_url'] as String?),
        isActive: json['is_active'] as bool? ?? true,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}
