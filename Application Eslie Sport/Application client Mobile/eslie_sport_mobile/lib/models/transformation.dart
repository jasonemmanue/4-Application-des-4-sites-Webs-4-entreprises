import '../config/api_config.dart';

class Transformation {
  final String id;
  final String memberName;
  final String? beforeImageUrl;
  final String? afterImageUrl;
  final String? testimonial;
  final String? durationText;
  final bool isFeatured;
  final bool isPublished;

  const Transformation({
    required this.id,
    required this.memberName,
    this.beforeImageUrl,
    this.afterImageUrl,
    this.testimonial,
    this.durationText,
    this.isFeatured = false,
    this.isPublished = true,
  });

  factory Transformation.fromJson(Map<String, dynamic> json) => Transformation(
        id: json['id'].toString(),
        memberName: json['member_name'] as String? ?? '',
        beforeImageUrl: ApiConfig.resolveMediaUrl(json['before_image_url'] as String?),
        afterImageUrl: ApiConfig.resolveMediaUrl(json['after_image_url'] as String?),
        testimonial: json['testimonial'] as String?,
        durationText: json['duration_text'] as String?,
        isFeatured: json['is_featured'] as bool? ?? false,
        isPublished: json['is_published'] as bool? ?? true,
      );
}
