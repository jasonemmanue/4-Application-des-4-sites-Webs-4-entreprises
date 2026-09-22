class Category {
  const Category({
    required this.id,
    required this.slug,
    required this.name,
    this.icon,
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String slug;
  final String name;
  final String? icon;
  final int order;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'].toString(),
        slug: json['slug'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        order: (json['order'] as num?)?.toInt() ?? 0,
        isActive: (json['is_active'] as bool?) ?? true,
      );
}
