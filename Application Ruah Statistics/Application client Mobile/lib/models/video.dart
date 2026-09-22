class Video {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? videoType;
  final bool isPublished;
  final int? order;
  final DateTime? createdAt;

  const Video({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.description,
    this.thumbnailUrl,
    this.videoType,
    this.isPublished = true,
    this.order,
    this.createdAt,
  });

  String get url => videoUrl;
  String? get thumbnail => thumbnailUrl;
  String? get category => videoType;

  String? get youtubeId {
    final Uri? uri = Uri.tryParse(videoUrl);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    return null;
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final String? p = json['created_at'] as String?;
    if (p != null) created = DateTime.tryParse(p);
    return Video(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoType: json['video_type'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
      order: json['order'] as int?,
      createdAt: created,
    );
  }
}
