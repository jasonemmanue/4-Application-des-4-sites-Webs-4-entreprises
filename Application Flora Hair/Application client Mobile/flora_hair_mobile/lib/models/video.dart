class Video {
  const Video({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.description,
    this.durationSeconds,
  });

  final String id;
  final String title;
  final String url;
  final String? thumbnailUrl;
  final String? description;
  final int? durationSeconds;

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'].toString(),
        title: json['title'] as String,
        url: (json['video_url'] ?? json['url'] ?? '') as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        description: json['description'] as String?,
        durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      );
}
