import '../config/api_config.dart';

class Project {
  final String id;
  final String slug;
  final String title;
  final String? clientName;
  final String? clientLogoUrl;
  final String? sector;
  final String? country;
  final int? year;
  final String? context;
  final String? solution;
  final String? results;
  final List<String> images;
  final bool isFeatured;
  final bool isPublished;
  final int? order;

  const Project({
    required this.id,
    required this.slug,
    required this.title,
    this.clientName,
    this.clientLogoUrl,
    this.sector,
    this.country,
    this.year,
    this.context,
    this.solution,
    this.results,
    this.images = const [],
    this.isFeatured = false,
    this.isPublished = true,
    this.order,
  });

  String? get coverImage {
    final raw = images.isNotEmpty ? images.first : clientLogoUrl;
    return ApiConfig.resolveMediaUrl(raw);
  }

  String? get clientLogo => ApiConfig.resolveMediaUrl(clientLogoUrl);
  List<String> get galleryUrls => images
      .map(ApiConfig.resolveMediaUrl)
      .whereType<String>()
      .toList(growable: false);
  String? get summary => context;
  String? get client => clientName;
  List<String> get gallery => images;
  List<ProjectFigure> get figures => const [];

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: (json['id'] ?? '').toString(),
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      clientName: json['client_name'] as String?,
      clientLogoUrl: json['client_logo_url'] as String?,
      sector: json['sector'] as String?,
      country: json['country'] as String?,
      year: json['year'] as int?,
      context: json['context'] as String?,
      solution: json['solution'] as String?,
      results: json['results'] as String?,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      isFeatured: json['is_featured'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
      order: json['order'] as int?,
    );
  }
}

class ProjectFigure {
  final String label;
  final String value;
  const ProjectFigure({required this.label, required this.value});
}
