import '../config/api_config.dart';

class Article {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String? excerpt;
  final String? coverImageUrl;
  final String status;
  final DateTime? publishedAt;
  final String? authorName;

  const Article({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.excerpt,
    this.coverImageUrl,
    this.status = 'published',
    this.publishedAt,
    this.authorName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return Article(
      id: json['id'].toString(),
      title: json['title'] as String,
      slug: json['slug'] as String,
      content: json['content'] as String? ?? '',
      excerpt: json['excerpt'] as String?,
      coverImageUrl: ApiConfig.resolveMediaUrl(json['cover_image_url'] as String?),
      status: json['status'] as String? ?? 'published',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      authorName: author is Map ? author['full_name'] as String? : null,
    );
  }
}
