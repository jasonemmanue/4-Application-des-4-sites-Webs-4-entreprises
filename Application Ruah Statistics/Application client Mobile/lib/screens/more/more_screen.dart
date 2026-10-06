import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/client_profile.dart';
import '../../services/whatsapp_service.dart';

const _whatsapp = WhatsAppService();

/// Profil — style Airbnb, palette cyan / charcoal de Ruah : carte
/// d'identité, deux cartes illustrées, une carte photo large, puis les
/// rubriques (icône + chevron).
///
/// Il n'y a pas de compte : le nom affiché est celui de la dernière
/// demande de devis envoyée depuis l'appareil, « Visiteur » sinon.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final _Palette p = _Palette(isDark);
    final ClientProfile profile = ref.watch(clientProfileProvider);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, AppSpacing.xl),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _RoundIconButton(
                palette: p,
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le cabinet vous répond sur WhatsApp.'),
                  ),
                ),
              ),
            ),
            Text(
              'Profil',
              style: TextStyle(
                color: p.fg,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _IdentityCard(palette: p, profile: profile),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _TileCard(
                    palette: p,
                    icon: Icons.request_quote_rounded,
                    title: 'Demander un devis',
                    onTap: () => context.push(AppRoutes.quote),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TileCard(
                    palette: p,
                    icon: Icons.insights_rounded,
                    title: 'Nos réalisations',
                    onTap: () => context.go(AppRoutes.projects),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _WideCard(
              palette: p,
              image: 'assets/images/profil-consultant.jpg',
              title: 'Parler à un consultant',
              description: 'Une question sur votre étude ? Échangez '
                  'directement avec le cabinet sur WhatsApp.',
              onTap: () => _whatsapp.sendPreFilledMessage(
                'Bonjour, je souhaite echanger avec ${ApiConfig.companyName}.',
              ),
            ),
            const SizedBox(height: 28),
            Divider(color: p.border, height: 1),
            _Tile(
              palette: p,
              icon: Icons.groups_outlined,
              label: 'Notre équipe',
              onTap: () => context.push(AppRoutes.team),
            ),
            _Tile(
              palette: p,
              icon: Icons.info_outline,
              label: 'À propos du cabinet',
              onTap: () => context.push(AppRoutes.about),
            ),
            _Tile(
              palette: p,
              icon: Icons.play_circle_outline,
              label: 'Vidéos',
              onTap: () => context.push(AppRoutes.videos),
            ),
            _Tile(
              palette: p,
              icon: Icons.rate_review_outlined,
              label: 'Témoignages clients',
              onTap: () => context.push(AppRoutes.testimonials),
            ),
            _Tile(
              palette: p,
              icon: Icons.mail_outline,
              label: 'Contacter le cabinet',
              onTap: () => context.push(AppRoutes.contact),
            ),
            Divider(color: p.border, height: 1),
            const SizedBox(height: AppSpacing.xl),
            const Center(
              child: Text(
                'RUAH-STATISTICS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand400,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Cabinet d\'études & conseil, Abidjan',
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Couleurs de l'écran selon le thème — l'app ne passe pas par un jeu de
/// tokens, chaque écran lit `brightness` (convention existante).
class _Palette {
  _Palette(this.isDark);
  final bool isDark;

  Color get bg => isDark ? AppColors.charcoal900 : AppColors.lightBg;
  Color get card => isDark ? AppColors.charcoal800 : Colors.white;
  Color get sunken => isDark ? AppColors.charcoal700 : const Color(0xFFEEF0F4);
  Color get fg => isDark ? Colors.white : AppColors.charcoal900;
  Color get muted => isDark ? Colors.white70 : Colors.black54;
  Color get border => isDark ? AppColors.charcoal700 : const Color(0xFFE5E7EB);

  /// Grand rayon + ombre douce. En sombre l'ombre se perd sur le charcoal :
  /// un contour fin prend le relais.
  BoxDecoration get cardDecoration => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: AppColors.charcoal700) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );
}

class _Pressable extends StatelessWidget {
  const _Pressable({
    required this.palette,
    required this.onTap,
    required this.child,
  });
  final _Palette palette;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: palette.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.palette,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final _Palette palette;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.sunken,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: palette.fg),
          ),
        ),
      ),
    );
  }
}

/// Avatar cyan pâle + nom. Le cyan remplace le vert d'Airbnb : c'est la
/// couleur de la marque.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.palette, required this.profile});
  final _Palette palette;
  final ClientProfile profile;

  @override
  Widget build(BuildContext context) {
    final String? name = profile.name;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: palette.cardDecoration,
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand500
                  .withValues(alpha: palette.isDark ? 0.18 : 0.14),
              shape: BoxShape.circle,
            ),
            child: name == null
                ? Icon(Icons.person_rounded,
                    size: 56,
                    color: palette.isDark
                        ? AppColors.brand400
                        : AppColors.brand800)
                : Text(
                    name.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: palette.isDark
                          ? AppColors.brand400
                          : AppColors.brand800,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            name ?? 'Visiteur',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.fg,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name == null
                ? 'Votre nom apparaîtra après votre première demande de devis'
                : (profile.company ?? 'Demande de devis envoyée'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte illustrée : le site du cabinet n'a qu'une photo, les deux petites
/// cartes portent donc une vignette en dégradé cyan de la marque.
class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final _Palette palette;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      palette: palette,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: palette.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  const _WideCard({
    required this.palette,
    required this.image,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final _Palette palette;
  final String image;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      palette: palette,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                image,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                // Décodage à la taille affichée : la photo fait 1920 px.
                cacheWidth:
                    (92 * MediaQuery.devicePixelRatioOf(context)).round(),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final _Palette palette;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: palette.fg),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.fg,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: palette.muted),
          ],
        ),
      ),
    );
  }
}
