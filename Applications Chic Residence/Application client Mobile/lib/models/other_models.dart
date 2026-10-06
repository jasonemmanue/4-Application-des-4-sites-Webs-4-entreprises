class Review {
  final String id;
  final String? residenceId;
  final String author;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool approved;

  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.approved,
    this.residenceId,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id']?.toString() ?? '',
        residenceId: json['residence_id']?.toString(),
        author: (json['author_name'] ?? json['author'])?.toString() ?? 'Anonyme',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        comment: json['comment']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        approved: json['approved'] == true || json['is_approved'] == true,
      );
}

class Article {
  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String cover;
  final DateTime publishedAt;

  const Article({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.cover,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        excerpt: (json['excerpt'] ?? json['summary'] ?? '').toString(),
        cover: (json['cover'] ?? json['cover_image'] ?? '').toString().isEmpty
            ? 'https://placehold.co/600x400/D4A05A/FFFFFF?text=Article'
            : (json['cover'] ?? json['cover_image']).toString(),
        publishedAt:
            DateTime.tryParse(json['published_at']?.toString() ?? '') ??
                DateTime.now(),
      );
}

class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;

  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        id: json['id']?.toString() ?? '',
        category: json['category']?.toString() ?? 'General',
        question: json['question']?.toString() ?? '',
        answer: json['answer']?.toString() ?? '',
      );
}

class AvailabilityDay {
  final DateTime date;
  final bool available;
  final String? reason;

  const AvailabilityDay({
    required this.date,
    required this.available,
    this.reason,
  });

  factory AvailabilityDay.fromJson(Map<String, dynamic> json) =>
      AvailabilityDay(
        date: DateTime.parse(json['date'].toString()),
        available: json['available'] == true || json['is_available'] == true,
        reason: json['reason']?.toString(),
      );
}
