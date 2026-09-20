class Subscription {
  final String id;
  final String name;
  final double price;
  final int durationMonths;
  final List<String> features;
  final bool isActive;
  final int order;

  const Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMonths,
    this.features = const [],
    this.isActive = true,
    this.order = 0,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'].toString(),
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        durationMonths: (json['duration_months'] as num?)?.toInt() ?? 1,
        features:
            (json['features'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        isActive: json['is_active'] as bool? ?? true,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}
