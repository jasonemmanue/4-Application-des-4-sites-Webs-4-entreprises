class Review {
  final String id;
  final String authorName;
  final int rating;
  final String? comment;
  final bool isApproved;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    this.comment,
    this.isApproved = false,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'].toString(),
        authorName: json['author_name'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        comment: json['comment'] as String?,
        isApproved: json['is_approved'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}
