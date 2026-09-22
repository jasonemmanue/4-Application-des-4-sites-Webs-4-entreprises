import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/gallery_item.dart';
import '../utils/media.dart';
import 'before_after_slider.dart';

class GalleryGrid extends StatelessWidget {
  const GalleryGrid({super.key, required this.items});
  final List<GalleryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _openLightbox(context, item),
          child: Hero(
            tag: 'gallery-${item.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              child: item.isBeforeAfter
                  ? BeforeAfterSlider(
                      beforeUrl: item.beforeUrl!,
                      afterUrl: item.afterUrl!,
                    )
                  : CachedNetworkImage(
                      imageUrl: mediaUrl(item.imageUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: FloraColors.darkLight),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _openLightbox(BuildContext context, GalleryItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _LightboxModal(item: item),
      ),
    );
  }
}

class _LightboxModal extends StatelessWidget {
  const _LightboxModal({required this.item});
  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Center(
            child: Hero(
              tag: 'gallery-${item.id}',
              child: InteractiveViewer(
                child: item.isBeforeAfter
                    ? BeforeAfterSlider(
                        beforeUrl: item.beforeUrl!,
                        afterUrl: item.afterUrl!,
                      )
                    : CachedNetworkImage(imageUrl: mediaUrl(item.imageUrl)),
              ),
            ),
          ),
          Positioned(
            top: 44,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
