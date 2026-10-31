import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Logo de la salle + nom, en haut a gauche de l'accueil.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ESLIE SPORT',
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESLIE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: size * 0.40,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1,
                ),
              ),
              Text(
                'SPORT',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: size * 0.40,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Titre avec le souligne jaune de la marque (« Trouve ton rythme »).
class UnderlinedTitle extends StatelessWidget {
  final String text;
  const UnderlinedTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 96,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ],
    );
  }
}

/// Fleche ronde, reprise sur les lignes d'activites et de formules.
class RoundArrow extends StatelessWidget {
  final Color background;
  final Color foreground;
  final double size;
  const RoundArrow({
    super.key,
    this.background = AppColors.primary,
    this.foreground = AppColors.onPrimary,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(Icons.arrow_forward_rounded,
          color: foreground, size: size * 0.55),
    );
  }
}
