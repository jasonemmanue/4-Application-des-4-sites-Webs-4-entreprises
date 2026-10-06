import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/member_profile.dart';

/// Profil — style Airbnb, palette Eslie : carte d'identité, deux cartes
/// photo, une carte large, puis les rubriques (icône + chevron).
///
/// Il n'y a pas de compte : le nom affiché est celui de la dernière
/// inscription faite depuis l'appareil, « Visiteur » sinon.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const _items = <_MoreItem>[
    _MoreItem(
        icon: Icons.groups_2_outlined, label: 'Coachs', route: '/coaches'),
    _MoreItem(
        icon: Icons.sports_gymnastics_outlined,
        label: 'Equipements',
        route: '/equipment'),
    _MoreItem(
        icon: Icons.compare_arrows_outlined,
        label: 'Transformations',
        route: '/transformations'),
    _MoreItem(
        icon: Icons.article_outlined, label: 'Articles', route: '/articles'),
    _MoreItem(
        icon: Icons.play_circle_outline, label: 'Videos', route: '/videos'),
    _MoreItem(
        icon: Icons.reviews_outlined, label: 'Avis clients', route: '/reviews'),
    _MoreItem(
        icon: Icons.calculate_outlined, label: 'Calcul IMC', route: '/bmi'),
    _MoreItem(icon: Icons.mail_outline, label: 'Contact', route: '/contact'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(memberNameProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _RoundIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Vos confirmations et rappels arrivent sur WhatsApp.'),
                  ),
                ),
              ),
            ),
            const Text(
              'Profil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            _IdentityCard(name: name),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PhotoCard(
                    image: 'assets/images/profil-formules.jpg',
                    title: 'Mes formules',
                    onTap: () => context.go('/subscriptions'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PhotoCard(
                    image: 'assets/images/profil-planning.jpg',
                    title: 'Planning des cours',
                    onTap: () => context.go('/schedule'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _WideCard(
              image: 'assets/images/profil-decouverte.jpg',
              title: 'Séance découverte',
              description:
                  "Envie d'essayer avant de vous lancer ? Réservez une séance "
                  'avec un coach, on en parle sur WhatsApp.',
              onTap: () => launchUrl(
                Uri.parse(
                  'https://wa.me/${ApiConfig.whatsappNumber}?text='
                  '${Uri.encodeComponent("Bonjour ESLIE SPORT, je souhaite réserver une séance découverte.")}',
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            for (final it in _items)
              _Tile(
                icon: it.icon,
                title: it.label,
                onTap: () => context.push(it.route),
              ),
            const Divider(),
            const SizedBox(height: 20),
            const _AboutCard(),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _MoreItem(
      {required this.icon, required this.label, required this.route});
}

/// Cadre commun des cartes : grand rayon, ombre douce, contour fin — sur
/// fond navy l'ombre seule ne suffit pas à détacher la carte.
final _cardDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: AppColors.border),
  boxShadow: AppShadows.card,
);

class _Pressable extends StatelessWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceElevated,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Avatar or pâle + nom. L'or remplace le vert d'Airbnb : c'est l'accent
/// unique de la marque.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: name == null
                ? const Icon(Icons.person_rounded,
                    size: 56, color: AppColors.primary)
                : Text(
                    name!.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            name ?? 'Visiteur',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name == null
                ? 'Votre nom apparaîtra après votre première inscription'
                : 'Membre',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
          // Décodage à la taille affichée : les photos font ~1600 px.
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
              height: 44,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
  const _Tile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ESLIE SPORT',
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(ApiConfig.slogan,
              style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 13)),
          const SizedBox(height: 12),
          _row(Icons.location_on_outlined, ApiConfig.gymLocation),
          _row(Icons.phone_outlined, ApiConfig.contactPhoneDisplay,
              onTap: () =>
                  launchUrl(Uri.parse('tel:${ApiConfig.contactPhone}'))),
          _row(Icons.chat_outlined, 'WhatsApp',
              onTap: () => launchUrl(
                  Uri.parse('https://wa.me/${ApiConfig.whatsappNumber}'))),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.darkMuted),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
