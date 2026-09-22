class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.imageUrl,
    this.title,
    this.beforeUrl,
    this.afterUrl,
    this.tags = const <String>[],
  });

  final String id;
  final String imageUrl;
  final String? title;
  final String? beforeUrl;
  final String? afterUrl;
  final List<String> tags;

  bool get isBeforeAfter =>
      (beforeUrl?.isNotEmpty ?? false) && (afterUrl?.isNotEmpty ?? false);

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    return GalleryItem(
      id: json['id'].toString(),
      imageUrl: (json['image_url'] as String?) ??
          (json['url'] as String?) ??
          (json['after_image_url'] as String?) ??
          '',
      title: json['title'] as String?,
      beforeUrl: (json['before_image_url'] as String?) ??
          (json['before_url'] as String?),
      afterUrl: (json['after_image_url'] as String?) ??
          (json['after_url'] as String?),
      tags: tagsRaw is List
          ? tagsRaw.map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}
