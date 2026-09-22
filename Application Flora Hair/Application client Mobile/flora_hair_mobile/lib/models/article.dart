class Article {
  const Article({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    this.content,
    this.coverUrl,
    this.author,
    this.publishedAt,
    this.readingMinutes,
    this.tags = const <String>[],
  });

  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String? content;
  final String? coverUrl;
  final String? author;
  final DateTime? publishedAt;
  final int? readingMinutes;
  final List<String> tags;

  factory Article.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    return Article(
      id: json['id'].toString(),
      slug: json['slug'] as String,
      title: json['title'] as String,
      excerpt: (json['excerpt'] as String?) ?? '',
      content: json['content'] as String?,
      coverUrl: (json['cover_image_url'] as String?) ??
          (json['cover_url'] as String?) ??
          (json['image_url'] as String?),
      author: json['author'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null),
      readingMinutes: (json['reading_minutes'] as num?)?.toInt(),
      tags: tagsRaw is List
          ? tagsRaw.map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}
