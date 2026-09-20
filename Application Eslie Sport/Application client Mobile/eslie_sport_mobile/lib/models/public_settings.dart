class PublicSettings {
  final String gymName;
  final String? tagline;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final Map<String, String> openingHours;
  final List<String> paymentMethods;

  const PublicSettings({
    required this.gymName,
    this.tagline,
    this.address,
    this.phone,
    this.whatsapp,
    this.email,
    this.openingHours = const {},
    this.paymentMethods = const [],
  });

  factory PublicSettings.fromJson(Map<String, dynamic> json) => PublicSettings(
        gymName: json['gym_name'] as String? ?? json['name'] as String? ?? 'ESLIE SPORT',
        tagline: json['tagline'] as String? ?? json['slogan'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        email: json['email'] as String?,
        openingHours:
            (json['opening_hours'] as Map?)?.map((k, v) => MapEntry(k as String, v.toString())) ??
                const {},
        paymentMethods:
            (json['payment_methods'] as List?)?.cast<String>() ?? const [],
      );
}
