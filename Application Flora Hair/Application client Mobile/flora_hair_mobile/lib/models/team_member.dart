class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    this.role,
    this.bio,
    this.photoUrl,
    this.specialties = const <String>[],
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? role;
  final String? bio;
  final String? photoUrl;
  final List<String> specialties;
  final int order;
  final bool isActive;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final rawSpecs = json['specialties'];
    final specs = rawSpecs is List
        ? rawSpecs.map((e) => e.toString()).toList()
        : <String>[];
    // Role : le backend ne retourne pas de "role" ; on prend la premiere
    // specialite comme role d'affichage si dispo.
    final firstSpec = specs.isNotEmpty ? specs.first : null;
    return TeamMember(
      id: json['id'].toString(),
      name: json['name'] as String,
      role: (json['role'] as String?) ?? firstSpec,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      specialties: specs,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}
