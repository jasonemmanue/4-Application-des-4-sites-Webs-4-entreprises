import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Cadre standard de l'application — fond, coins arrondis, bordure fine et
/// ombre douce.
///
/// C'est le « beau petit cadre » qu'on retrouve partout chez Airbnb : cards
/// de logement, encarts, blocs d'information. Centraliser sa définition évite
/// que chaque écran réinvente un rayon et une ombre légèrement différents —
/// c'est ce qui donnait une impression d'incohérence d'un écran à l'autre.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 18,
    this.onTap,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// `false` retire l'ombre : utile quand le cadre est déjà posé sur une
  /// surface élevée (feuille modale, autre card).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shape = BorderRadius.circular(radius);

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: shape,
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: t.shadow,
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
