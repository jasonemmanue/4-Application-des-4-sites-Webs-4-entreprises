import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../services/favorites.dart';
import '../utils/media.dart';

/// Briques visuelles communes de la refonte.

const _frWeekdays = <String>['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const _frMonths = <String>[
  'Janv.', 'Févr.', 'Mars', 'Avr.', 'Mai', 'Juin',
  'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.',
];

String frWeekday(DateTime d) => _frWeekdays[d.weekday - 1];
String frMonth(DateTime d) => _frMonths[d.month - 1];

/// `Mar. 04 Nov. 2026`
String frLongDate(DateTime d) =>
    '${frWeekday(d)}. ${d.day.toString().padLeft(2, '0')} ${frMonth(d)} ${d.year}';

/// Photo venant de l'API, avec une vignette de marque quand il n'y en a pas :
/// une partie du catalogue n'a pas encore de visuel dans l'administration.
class FloraImage extends StatelessWidget {
  const FloraImage({
    super.key,
    required this.url,
    this.label,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.icon = Icons.spa_outlined,
  });

  final String? url;
  final String? label;
  final BoxFit fit;
  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: FloraColors.blushLight,
      child: Center(child: Icon(icon, color: FloraColors.burgundy, size: 30)),
    );
    if (url == null || url!.trim().isEmpty) return placeholder;
    return Semantics(
      label: label,
      image: label != null,
      child: CachedNetworkImage(
        imageUrl: mediaUrl(url),
        fit: fit,
        alignment: alignment,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => const ColoredBox(color: FloraColors.blushLight),
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// Cœur des favoris — état partagé par toutes les vignettes.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.favoriteKey,
    this.size = 34,
    this.label = 'favori',
  });

  final String favoriteKey;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(favoritesProvider).contains(favoriteKey);
    return Semantics(
      button: true,
      selected: active,
      label: active ? 'Retirer des favoris : $label' : 'Ajouter aux favoris : $label',
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ref.read(favoritesProvider.notifier).toggle(favoriteKey),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: FloraColors.burgundy,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

class FloraSectionHeader extends StatelessWidget {
  const FloraSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 12, 10),
  });

  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: FloraColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: FloraColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 40),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Voir tout',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte blanche à grand rayon et ombre douce.
class FloraCard extends StatelessWidget {
  const FloraCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FloraTheme.cardRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FloraColors.surface,
        borderRadius: radius,
        boxShadow: floraCardShadow,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.6)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Pastille de filtre : bordeaux plein quand elle est active.
class FloraFilterChip extends StatelessWidget {
  const FloraFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? FloraColors.burgundy : FloraColors.blushLight,
        borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : FloraColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Étiquette d'état d'un rendez-vous, telle que décidée par le salon.
class AppointmentStatusBadge extends StatelessWidget {
  const AppointmentStatusBadge({
    super.key,
    required this.status,
    required this.depositPaid,
  });

  final String status;
  final bool depositPaid;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (status) {
      'confirmed' => ('Confirmé', FloraColors.successSoft, FloraColors.success),
      'completed' => ('Terminé', FloraColors.blushLight, FloraColors.burgundy),
      'cancelled' => ('Annulé', FloraColors.dangerSoft, FloraColors.danger),
      _ when depositPaid =>
        ('Acompte payé', FloraColors.successSoft, FloraColors.success),
      _ => ('En attente', FloraColors.warningSoft, FloraColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Icône d'une catégorie du catalogue. Les catégories sont gérées dans
/// l'administration : un slug inconnu retombe sur l'icône générique.
IconData categoryIcon(String slug) {
  if (slug.contains('homme')) return Icons.face_6_outlined;
  if (slug.contains('coiff') || slug.contains('natte')) {
    return Icons.content_cut_rounded;
  }
  if (slug.contains('maquill')) return Icons.brush_outlined;
  if (slug.contains('ongl')) return Icons.back_hand_outlined;
  if (slug.contains('soin')) return Icons.spa_outlined;
  if (slug.contains('perruque') || slug.contains('tissage')) {
    return Icons.face_3_outlined;
  }
  return Icons.auto_awesome_outlined;
}
