import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/whatsapp_service.dart';

/// Profil — style Airbnb : carte d'identité, deux cartes photo, une carte
/// large, puis les réglages (icône + chevron).
///
/// Il n'y a pas de compte : le nom affiché est celui de la dernière
/// réservation faite depuis l'appareil, « Visiteur » sinon.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, context.bottomInset()),
          children: [
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _RoundIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Vos confirmations et rappels arrivent sur WhatsApp.'),
                    ),
                  );
                },
              ),
            ),
            Text(
              'Profil',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            _IdentityCard(name: ref.watch(guestNameProvider)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PhotoCard(
                    image: 'assets/images/profil-reservations.jpg',
                    title: 'Mes réservations',
                    onTap: () => context.go('/bookings'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PhotoCard(
                    image: 'assets/images/profil-favoris.jpg',
                    title: 'Mes favoris',
                    onTap: () => context.go('/favorites'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _WideCard(
              image: 'assets/images/profil-proposer.jpg',
              title: 'Proposer votre logement',
              description:
                  'Confiez votre bien meublé à CHIC RESIDENCE et percevez des '
                  'revenus supplémentaires. On en parle sur WhatsApp.',
              onTap: () => WhatsAppService.send(
                "Bonjour CHIC RESIDENCE, je souhaite proposer mon logement "
                'en location meublée.',
              ),
            ),
            const SizedBox(height: 28),
            Divider(height: 1, color: t.border),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.settings_outlined,
              title: 'Paramètres du compte',
              onTap: () {},
            ),
            _Tile(
              icon: Icons.help_outline_rounded,
              title: "Obtenir de l'aide",
              onTap: () {},
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: t.border),
            const SizedBox(height: 16),
            const _SectionLabel('Apparence'),
            const _ThemeToggle(),
            const SizedBox(height: 16),
            Divider(height: 1, color: t.border),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.menu_book_outlined,
              title: 'Mentions légales',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'v1.0.0 · ${ApiConfig.contactPhone}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: t.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cadre commun des cartes du Profil : grand rayon, ombre douce. En sombre,
/// l'ombre ne se voit plus — un contour fin prend le relais.
BoxDecoration _cardDecoration(AppTokens t) => BoxDecoration(
      color: t.surfaceElevated,
      borderRadius: BorderRadius.circular(22),
      border: t.isDark ? Border.all(color: t.border) : null,
      boxShadow: [
        BoxShadow(
          color: t.shadow.withValues(alpha: t.isDark ? 0.4 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );

class _Pressable extends StatelessWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: _cardDecoration(t),
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
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: t.surfaceSunken,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: t.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Avatar vert pâle + nom. Le vert n'est pas une couleur de la marque :
/// c'est la convention Airbnb de l'avatar par défaut, gardée telle quelle.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final avatarBg =
        t.isDark ? const Color(0xFF1E3A26) : const Color(0xFFDDF1E3);
    final avatarFg =
        t.isDark ? const Color(0xFF8FD19E) : const Color(0xFF1B6B2E);
    final display = name ?? 'Visiteur';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: _cardDecoration(t),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
            child: name == null
                ? Icon(Icons.person_rounded, size: 56, color: avatarFg)
                : Text(
                    name!.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: avatarFg,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            name == null
                ? 'Votre nom apparaîtra après votre première réservation'
                : 'Voyageur',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: t.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.size});
  final String image;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Décodage à la taille affichée : les photos font ~800 px.
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      );
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.image,
    required this.title,
    required this.onTap,
  });
  final String image;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            _Thumb(image: image, size: 92),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
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
    required this.image,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final String image;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _Thumb(image: image, size: 92),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: t.textSecondary, height: 1.35),
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
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 26, color: t.textPrimary),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

/// Bascule clair / auto / sombre — soleil, cercle, lune.
///
/// Trois options plutôt que deux : l'auto suit le réglage système et évite de
/// rebasculer manuellement chaque matin. C'est le défaut au premier lancement.
class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.wb_sunny_rounded),
          label: Text('Clair'),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_rounded),
          label: Text('Auto'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.nightlight_round),
          label: Text('Sombre'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => notifier.set(s.first),
      showSelectedIcon: false,
    );
  }
}
