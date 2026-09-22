import '../config/api_config.dart';

enum ArticleType { article, whitepaper, other }

class Article {
  final String id;
  final String slug;
  final String title;
  final String? content;
  final String? excerpt;
  final String? coverImageUrl;
  final ArticleType articleType;
  final String? fileUrl;
  final String? status;
  final DateTime? publishedAt;
  final String? authorId;
  final Map<String, dynamic>? author;
  final DateTime? createdAt;

  const Article({
    required this.id,
    required this.slug,
    required this.title,
    this.content,
    this.excerpt,
    this.coverImageUrl,
    this.articleType = ArticleType.article,
    this.fileUrl,
    this.status,
    this.publishedAt,
    this.authorId,
    this.author,
    this.createdAt,
  });

  ArticleType get type => articleType;
  bool get isWhitepaper => articleType == ArticleType.whitepaper;
  String? get coverImage => ApiConfig.resolveMediaUrl(coverImageUrl);
  String? get fileDownloadUrl => ApiConfig.resolveMediaUrl(fileUrl);
  String? get downloadUrl => fileUrl;
  bool get requiresEmail => isWhitepaper;
  String? get authorName {
    if (author == null) return null;
    return author!['name'] as String? ?? author!['full_name'] as String?;
  }

  List<String> get tags => const [];

  factory Article.fromJson(Map<String, dynamic> json) {
    final String? raw = (json['article_type'] as String?)?.toLowerCase();
    ArticleType t = ArticleType.article;
    if (raw == 'whitepaper' ||
        raw == 'livre_blanc' ||
        raw == 'livre-blanc' ||
        raw == 'white_paper') {
      t = ArticleType.whitepaper;
    } else if (raw != null && raw != 'article') {
      t = ArticleType.other;
    }

    DateTime? _parse(String? v) => v != null ? DateTime.tryParse(v) : null;

    return Article(
      id: (json['id'] ?? '').toString(),
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      excerpt: json['excerpt'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      articleType: t,
      fileUrl: json['file_url'] as String?,
      status: json['status'] as String?,
      publishedAt: _parse(json['published_at'] as String?),
      authorId: json['author_id']?.toString(),
      author: json['author'] is Map<String, dynamic>
          ? json['author'] as Map<String, dynamic>
          : null,
      createdAt: _parse(json['created_at'] as String?),
    );
  }
}
