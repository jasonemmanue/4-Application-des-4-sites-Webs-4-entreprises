import 'package:flutter/material.dart';

import '../config/theme.dart';

/// En-tête de section « catalogue » : titre gras à gauche, chevron rond
/// à droite si l'on peut approfondir. C'est le motif visuel des grandes
/// listes en accueil (Airbnb, catalogues type).
class SectionHeaderRow extends StatelessWidget {
  const SectionHeaderRow({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: FloraColors.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: FloraColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: FloraColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: FloraColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
