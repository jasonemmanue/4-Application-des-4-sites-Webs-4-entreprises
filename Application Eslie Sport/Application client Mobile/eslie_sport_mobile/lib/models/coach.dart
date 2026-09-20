class Coach {
  final String id;
  final String name;
  final String? photoUrl;
  final List<String> certifications;
  final List<String> specialties;
  final String? bio;
  final bool isActive;
  final int order;

  const Coach({
    required this.id,
    required this.name,
    this.photoUrl,
    this.certifications = const [],
    this.specialties = const [],
    this.bio,
    this.isActive = true,
    this.order = 0,
  });

  factory Coach.fromJson(Map<String, dynamic> json) => Coach(
        id: json['id'].toString(),
        name: json['name'] as String,
        photoUrl: json['photo_url'] as String?,
        certifications:
            (json['certifications'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        specialties:
            (json['specialties'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        bio: json['bio'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}
