import '../config/api_config.dart';

class Video {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String category;
  final bool isPublished;
  final int order;

  const Video({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.category = '',
    this.isPublished = true,
    this.order = 0,
  });

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'].toString(),
        title: json['title'] as String,
        description: json['description'] as String?,
        videoUrl: ApiConfig.resolveMediaUrl(json['video_url'] as String?) ?? '',
        thumbnailUrl: ApiConfig.resolveMediaUrl(json['thumbnail_url'] as String?),
        category: json['category'] as String? ?? '',
        isPublished: json['is_published'] as bool? ?? true,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}
