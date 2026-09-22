import '../config/api_config.dart';

class TeamMember {
  final String id;
  final String name;
  final String? titlePosition;
  final String? photoUrl;
  final List<String> specialties;
  final int? experienceYears;
  final String? education;
  final String? linkedinUrl;
  final String? bio;
  final int? order;
  final bool isActive;

  const TeamMember({
    required this.id,
    required this.name,
    this.titlePosition,
    this.photoUrl,
    this.specialties = const [],
    this.experienceYears,
    this.education,
    this.linkedinUrl,
    this.bio,
    this.order,
    this.isActive = true,
  });

  String? get role => titlePosition;
  String? get photo => ApiConfig.resolveMediaUrl(photoUrl);
  String? get linkedin => linkedinUrl;
  String? get email => null;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      titlePosition: json['title_position'] as String?,
      photoUrl: json['photo_url'] as String?,
      specialties:
          (json['specialties'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      experienceYears: json['experience_years'] as int?,
      education: json['education'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      bio: json['bio'] as String?,
      order: json['order'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
