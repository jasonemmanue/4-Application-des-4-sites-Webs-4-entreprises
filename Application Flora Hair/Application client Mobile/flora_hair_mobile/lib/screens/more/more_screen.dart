import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/client_profile.dart';

/// Profil — style Airbnb, palette Flora : carte d'identité, deux cartes
/// photo, une carte large, puis les rubriques (icône + chevron).
///
/// Il n'y a pas de compte : le nom affiché est celui du dernier rendez-vous
/// pris depuis l'appareil, « Visiteuse » sinon.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const _tiles = <_MoreTile>[
    _MoreTile('Notre équipe', Icons.groups_outlined, '/team'),
    _MoreTile('Articles beauté', Icons.menu_book_outlined, '/articles'),
    _MoreTile('Vidéos', Icons.play_circle_outline, '/videos'),
    _MoreTile('Avis clients', Icons.star_outline, '/reviews'),
    _MoreTile('Formations', Icons.school_outlined, '/training'),
    _MoreTile('Contact & WhatsApp', Icons.chat_bubble_outline, '/contact'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final name = ref.watch(clientNameProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
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
          Text(
            'Profil',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          _IdentityCard(name: name),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _PhotoCard(
                  image: 'assets/images/profil-rdv.jpg',
                  title: 'Prendre rendez-vous',
                  onTap: () => context.go('/booking'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PhotoCard(
                  image: 'assets/images/profil-galerie.jpg',
                  title: 'Nos réalisations',
                  onTap: () => context.go('/gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WideCard(
            image: 'assets/images/profil-devis.jpg',
            title: 'Devis sur photo',
            description: 'Envoyez la photo de la coiffure qui vous fait '
                'envie, on vous répond avec un prix.',
            onTap: () => context.push('/quote'),
          ),
          const SizedBox(height: 28),
          const Divider(),
          for (final t in _tiles)
            _Tile(
              icon: t.icon,
              title: t.label,
              onTap: () => context.push(t.route),
            ),
        ],
      ),
    );
  }
}

class _MoreTile {
  const _MoreTile(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

/// Cadre commun des cartes : grand rayon, ombre douce chaude (teintée
/// chocolat plutôt que noire, pour rester dans la palette crème).
BoxDecoration _cardDecoration(ColorScheme cs) => BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x1F1A1510),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );

class _Pressable extends StatelessWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(Theme.of(context).colorScheme),
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
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerHighest,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Avatar or pâle + nom. L'or remplace le vert d'Airbnb : c'est l'accent de
/// la marque.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: _cardDecoration(cs),
      child: Column(
        children: <Widget>[
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: name == null
                ? Icon(Icons.person_rounded, size: 56, color: cs.secondary)
                : Text(
                    name!.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      // Or foncé : l'or standard manque de contraste sur
                      // le disque or pâle.
                      color: Color(0xFF8A6D24),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            name ?? 'Visiteuse',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name == null
                ? 'Votre nom apparaîtra après votre premier rendez-vous'
                : 'Cliente Flora Hair',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    return _Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: <Widget>[
            _Thumb(image: image, size: 92),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;
    return _Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            _Thumb(image: image, size: 92),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 24, color: cs.onSurface),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
