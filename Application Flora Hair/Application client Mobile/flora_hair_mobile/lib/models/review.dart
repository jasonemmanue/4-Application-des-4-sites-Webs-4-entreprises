class Review {
  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    this.photoUrl,
    this.isApproved = true,
    this.createdAt,
  });

  final String id;
  final String author;
  final int rating; // 1..5
  final String comment;
  final String? photoUrl;
  final bool isApproved;
  final DateTime? createdAt;

  /// Compat : plusieurs ecrans lisent `review.serviceName`. L'API n'expose pas
  /// ce champ, on renvoie null pour ne pas casser leur affichage conditionnel.
  String? get serviceName => null;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'].toString(),
        author: (json['author_name'] as String?) ??
            (json['author'] as String?) ??
            'Anonyme',
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        comment: (json['comment'] as String?) ?? '',
        photoUrl: json['photo_url'] as String?,
        isApproved: (json['is_approved'] as bool?) ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class ReviewSubmission {
  const ReviewSubmission({
    required this.author,
    required this.rating,
    required this.comment,
    this.email,
    this.serviceId,
  });

  final String author;
  final int rating;
  final String comment;
  final String? email;
  final String? serviceId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'author_name': author,
        'rating': rating,
        'comment': comment,
      };
}
