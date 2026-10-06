import '../config/api_config.dart';

class Equipment {
  final String id;
  final String name;
  final String? description;
  final String zone;
  final String? imageUrl;
  final int quantity;
  final bool isActive;

  const Equipment({
    required this.id,
    required this.name,
    this.description,
    required this.zone,
    this.imageUrl,
    this.quantity = 1,
    this.isActive = true,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'].toString(),
        name: json['name'] as String,
        description: json['description'] as String?,
        zone: json['zone'] as String? ?? 'Divers',
        imageUrl: ApiConfig.resolveMediaUrl(json['image_url'] as String?),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        isActive: json['is_active'] as bool? ?? true,
      );
}
