/// Parametres publics, modifiables depuis le back-office.
///
/// L'API renvoie uniquement des chaines (`gym_name`, `address`, `phone`,
/// `opening_hours`, `map_url`, reseaux sociaux...). Une valeur vide vaut absence.
class PublicSettings {
  final String gymName;
  final String? tagline;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? openingHours;
  final String? mapUrl;

  const PublicSettings({
    required this.gymName,
    this.tagline,
    this.address,
    this.phone,
    this.whatsapp,
    this.openingHours,
    this.mapUrl,
  });

  /// Numero international sans `+`, pour `wa.me`.
  String? get whatsappDigits {
    final raw = whatsapp ?? phone;
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : digits;
  }

  factory PublicSettings.fromJson(Map<String, dynamic> json) => PublicSettings(
        gymName: _text(json['gym_name']) ?? 'ESLIE SPORT',
        tagline: _text(json['tagline']) ?? _text(json['slogan']),
        address: _text(json['address']),
        phone: _text(json['phone']),
        whatsapp: _text(json['whatsapp']),
        openingHours: _text(json['opening_hours']),
        mapUrl: _text(json['map_url']),
      );

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
