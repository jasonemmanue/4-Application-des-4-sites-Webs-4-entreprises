import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Briques visuelles de la refonte 1.1 : en-tête logo, titres avec filet
/// ambre, cartes douces, icônes d'expertise, images réseau avec repli.

bool isDarkOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color fgOf(BuildContext context) =>
    isDarkOf(context) ? Colors.white : AppColors.charcoal900;

Color mutedOf(BuildContext context) =>
    isDarkOf(context) ? Colors.white70 : AppColors.lightMuted;

BoxDecoration softCard(BuildContext context, {double radius = 18}) {
  final bool dark = isDarkOf(context);
  return BoxDecoration(
    color: dark ? AppColors.charcoal800 : Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
        color: dark ? AppColors.charcoal700 : AppColors.lightBorder),
    boxShadow: [
      BoxShadow(
        color: AppColors.charcoal900.withValues(alpha: dark ? 0.3 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// Logo du cabinet + nom. Le logo a des traits noirs : en thème sombre, il est
/// posé sur une pastille blanche pour rester lisible.
class RuahLogo extends StatelessWidget {
  const RuahLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    final TextStyle style = TextStyle(
      fontSize: 18,
      height: 1.05,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: fgOf(context),
    );
    return Semantics(
      label: 'Ruah Statistics',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: dark ? const EdgeInsets.all(3) : EdgeInsets.zero,
              decoration: dark
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Image.asset('assets/images/logo.png',
                  width: 50, height: 50, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RUAH', style: style),
                Text('STATISTICS', style: style),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RuahHeader extends StatelessWidget {
  const RuahHeader({super.key, this.actions = const []});
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
      child: Row(
        children: [
          const RuahLogo(),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

class AccentBar extends StatelessWidget {
  const AccentBar({super.key, this.width = 64});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.accent500,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent = true,
  });
  final String title;
  final String subtitle;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: fgOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 16, height: 1.35, color: mutedOf(context)),
          ),
          if (accent) ...[
            const SizedBox(height: 12),
            const AccentBar(),
          ],
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: fgOf(context),
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Voir tout',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Le champ `icon` de l'API contient un nom d'icône du site web (lucide) :
/// le titre du service est un repère plus stable pour choisir l'icône mobile.
IconData expertiseIcon(String title) {
  final String t = title.toLowerCase();
  if (t.contains('faisabilit')) return Icons.bar_chart_rounded;
  if (t.contains('strat')) return Icons.track_changes_rounded;
  if (t.contains('impact')) return Icons.public_rounded;
  if (t.contains('audit')) return Icons.balance_rounded;
  if (t.contains('formation')) return Icons.school_rounded;
  return Icons.insights_rounded;
}

class ExpertiseBadge extends StatelessWidget {
  const ExpertiseBadge({super.key, required this.title, this.size = 46});
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? AppColors.charcoal700 : AppColors.brandTint,
        shape: BoxShape.circle,
      ),
      child: Icon(
        expertiseIcon(title),
        size: size * 0.55,
        color: dark ? Colors.white : AppColors.brand600,
      ),
    );
  }
}

class RoundAction extends StatelessWidget {
  const RoundAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: fgOf(context), size: 26),
    );
  }
}

/// Image distante : dégradé de marque pendant le chargement, et si l'URL est
/// vide, introuvable ou dans un format non décodable (SVG téléversé depuis
/// l'admin, par exemple).
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.semanticLabel,
    this.fallbackIcon = Icons.insights_rounded,
    this.fit = BoxFit.cover,
  });
  final String? url;
  final String semanticLabel;
  final IconData fallbackIcon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final String? u = url;
    if (u == null || u.isEmpty) return _fallback();
    return Semantics(
      image: true,
      label: semanticLabel,
      child: CachedNetworkImage(
        imageUrl: u,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 1000,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholder: (_, __) => _fallback(showIcon: false),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback({bool showIcon = true}) => Container(
        decoration: const BoxDecoration(gradient: AppColors.ctaGradient),
        alignment: Alignment.center,
        child: showIcon
            ? Icon(fallbackIcon, color: Colors.white70, size: 40)
            : null,
      );
}

/// Photo de personne ; initiales tant qu'aucune photo n'est téléversée depuis
/// l'admin, ou si elle ne se charge pas.
class RemoteAvatar extends StatelessWidget {
  const RemoteAvatar({
    super.key,
    required this.url,
    required this.name,
    this.radius = 32,
  });
  final String? url;
  final String name;
  final double radius;

  String get _initials {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty && !p.endsWith('.'))
        .take(2);
    return parts.map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    final Widget initials = Container(
      alignment: Alignment.center,
      color: dark ? AppColors.charcoal700 : AppColors.brandTint,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : AppColors.brand600,
        ),
      ),
    );
    final String? u = url;
    return Semantics(
      image: true,
      label: 'Photo de $name',
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: (u == null || u.isEmpty)
              ? initials
              : CachedNetworkImage(
                  imageUrl: u,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  placeholder: (_, __) => initials,
                  errorWidget: (_, __, ___) => initials,
                ),
        ),
      ),
    );
  }
}
