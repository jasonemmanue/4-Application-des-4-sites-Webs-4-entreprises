class KeyFigure {
  final String id;
  final String label;
  final num value;
  final String? suffix;
  final String? icon;
  final int? order;

  const KeyFigure({
    required this.id,
    required this.label,
    required this.value,
    this.suffix,
    this.icon,
    this.order,
  });

  factory KeyFigure.fromJson(Map<String, dynamic> json) {
    return KeyFigure(
      id: (json['id'] ?? '').toString(),
      label: json['label'] as String? ?? json['title'] as String? ?? '',
      value: (json['value'] as num?) ?? 0,
      suffix: json['suffix'] as String? ?? json['unit'] as String?,
      icon: json['icon'] as String?,
      order: json['order'] as int?,
    );
  }
}
