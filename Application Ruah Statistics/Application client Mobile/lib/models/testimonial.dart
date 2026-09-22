class Testimonial {
  final String id;
  final String clientName;
  final String? clientPosition;
  final String? clientCompany;
  final String? clientPhotoUrl;
  final String? clientWhatsapp;
  final String quote;
  final int? rating;
  final bool isFeatured;
  final int? order;
  final DateTime? createdAt;

  const Testimonial({
    required this.id,
    required this.clientName,
    required this.quote,
    this.clientPosition,
    this.clientCompany,
    this.clientPhotoUrl,
    this.clientWhatsapp,
    this.rating,
    this.isFeatured = false,
    this.order,
    this.createdAt,
  });

  String get author => clientName;
  String? get role => clientPosition;
  String? get company => clientCompany;
  String? get photo => clientPhotoUrl;
  String get message => quote;

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final String? p = json['created_at'] as String?;
    if (p != null) created = DateTime.tryParse(p);
    return Testimonial(
      id: (json['id'] ?? '').toString(),
      clientName: json['client_name'] as String? ?? '',
      clientPosition: json['client_position'] as String?,
      clientCompany: json['client_company'] as String?,
      clientPhotoUrl: json['client_photo_url'] as String?,
      clientWhatsapp: json['client_whatsapp'] as String?,
      quote: json['quote'] as String? ?? '',
      rating: json['rating'] as int?,
      isFeatured: json['is_featured'] as bool? ?? false,
      order: json['order'] as int?,
      createdAt: created,
    );
  }
}
