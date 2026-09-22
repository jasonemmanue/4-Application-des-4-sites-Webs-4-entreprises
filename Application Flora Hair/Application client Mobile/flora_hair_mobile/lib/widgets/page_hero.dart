import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/theme.dart';
import '../utils/media.dart';

class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundUrl,
    this.height = 220,
  });

  final String title;
  final String? subtitle;
  final String? backgroundUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (backgroundUrl != null && backgroundUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: mediaUrl(backgroundUrl),
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: FloraColors.charcoal),
            )
          else
            Container(
              decoration: const BoxDecoration(gradient: FloraColors.goldGradient),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: FloraColors.cream),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: FloraColors.cream.withValues(alpha: 0.85),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
