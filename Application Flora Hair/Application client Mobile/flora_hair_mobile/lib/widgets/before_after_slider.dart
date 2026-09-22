import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/media.dart';

/// Slider avant/apres — deux images superposees, un ClipRect anime
/// dont la largeur suit le drag du doigt (equivalent clip-path CSS).
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    this.initialPosition = 0.5,
  });

  final String beforeUrl;
  final String afterUrl;
  final double initialPosition;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            _position = (details.localPosition.dx / width).clamp(0.0, 1.0);
          });
        },
        onTapDown: (details) {
          setState(() {
            _position = (details.localPosition.dx / width).clamp(0.0, 1.0);
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CachedNetworkImage(imageUrl: mediaUrl(widget.afterUrl), fit: BoxFit.cover),
            ClipRect(
              clipper: _LeftClipper(position: _position),
              child: CachedNetworkImage(
                imageUrl: mediaUrl(widget.beforeUrl),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: width * _position - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: FloraColors.lime),
            ),
            Positioned(
              left: width * _position - 18,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: FloraColors.lime,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.swap_horiz,
                      size: 20, color: FloraColors.dark),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _tag('Avant'),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: _tag('Apres'),
            ),
          ],
        ),
      );
    });
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: FloraColors.dark.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: FloraColors.cream,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _LeftClipper extends CustomClipper<Rect> {
  const _LeftClipper({required this.position});
  final double position;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) =>
      oldClipper.position != position;
}
