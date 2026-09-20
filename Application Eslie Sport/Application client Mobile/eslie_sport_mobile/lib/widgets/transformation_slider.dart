import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/transformation.dart';

class TransformationSlider extends StatefulWidget {
  final Transformation transformation;
  const TransformationSlider({super.key, required this.transformation});

  @override
  State<TransformationSlider> createState() => _TransformationSliderState();
}

class _TransformationSliderState extends State<TransformationSlider> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    final t = widget.transformation;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _image(t.afterImageUrl,
                        label: 'APRES', color: AppColors.success),
                  ),
                  ClipRect(
                    clipper: _LeftClipper(_position),
                    child: _image(t.beforeImageUrl,
                        label: 'AVANT', color: AppColors.warning),
                  ),
                  Positioned(
                    left: width * _position - 12,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (d) {
                        setState(() {
                          _position = (_position + d.delta.dx / width)
                              .clamp(0.05, 0.95);
                        });
                      },
                      child: Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Container(
                          width: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(t.memberName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              )),
          if (t.durationText != null)
            Text(t.durationText!,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          if (t.testimonial != null) ...[
            const SizedBox(height: 4),
            Text(t.testimonial!,
                style: const TextStyle(
                    color: AppColors.darkMuted, fontSize: 13)),
          ],
        ],
      );
    });
  }

  Widget _image(String? url, {required String label, required Color color}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: AppColors.darkLighter),
              )
            : Container(color: AppColors.darkLighter),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                )),
          ),
        ),
      ],
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double position;
  _LeftClipper(this.position);
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width * position, size.height);
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}
