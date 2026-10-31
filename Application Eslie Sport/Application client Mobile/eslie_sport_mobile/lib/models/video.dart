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

  /// Le back-office peut stocker un simple nom de fichier sans l'avoir mis en
  /// ligne : seule une URL absolue ou un fichier televerse est lisible.
  final bool isPlayable;

  const Video({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.category = '',
    this.isPublished = true,
    this.order = 0,
    this.isPlayable = true,
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
        isPlayable: _isHosted(json['video_url'] as String?),
      );

  static bool _isHosted(String? raw) {
    final path = raw?.trim() ?? '';
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('/uploads/');
  }
}
