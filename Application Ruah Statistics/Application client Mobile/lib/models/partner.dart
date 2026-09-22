import '../config/api_config.dart';

class Partner {
  final String id;
  final String name;
  final String? logoUrl;
  final String? websiteUrl;
  final String? partnerType;
  final int? order;
  final bool isActive;

  const Partner({
    required this.id,
    required this.name,
    this.logoUrl,
    this.websiteUrl,
    this.partnerType,
    this.order,
    this.isActive = true,
  });

  String? get logo => ApiConfig.resolveMediaUrl(logoUrl);
  String? get website => websiteUrl;

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      partnerType: json['partner_type'] as String?,
      order: json['order'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
