import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/appointments.dart';
import '../../services/client_profile.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/flora_ui.dart';
import '../appointments/appointments_screen.dart';

/// « Mon espace » : prochain rendez-vous, accès rapides, salon et rubriques.
///
/// Il n'y a pas de compte : le nom affiché est celui du dernier rendez-vous pris
/// depuis l'appareil.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  static const _tiles = <_MoreTile>[
    _MoreTile('Galerie & réalisations', Icons.photo_library_outlined, '/gallery'),
    _MoreTile('Devis sur photo', Icons.add_a_photo_outlined, '/quote'),
    _MoreTile('Notre équipe', Icons.groups_outlined, '/team'),
    _MoreTile('Articles beauté', Icons.menu_book_outlined, '/articles'),
    _MoreTile('Vidéos', Icons.play_circle_outline, '/videos'),
    _MoreTile('Avis clients', Icons.star_outline, '/reviews'),
    _MoreTile('Formations', Icons.school_outlined, '/training'),
  ];

  @override
  void initState() {
    super.initState();
    // Le rendez-vous a pu être confirmé dans l'administration entre-temps.
    Future<void>.microtask(
        () => ref.read(appointmentsProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(clientNameProvider);
    final next = ref.watch(nextAppointmentProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          const Center(
            child: Text(
              'Mon espace',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: FloraColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Greeting(name: name),
          const SizedBox(height: 18),
          FloraCard(
            child: next == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Prochain rendez-vous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: FloraColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Vous n'avez pas de rendez-vous à venir.",
                        style: TextStyle(color: FloraColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/booking'),
                        child: const Text('Prendre rendez-vous'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Prochain rendez-vous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: FloraColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppointmentCard(appointment: next, showActions: false),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push('/appointments'),
                        child: const Text('Voir les détails  →'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: <Widget>[
              _QuickAction(
                icon: Icons.calendar_month_outlined,
                label: 'Mes rendez-vous',
                onTap: () => context.push('/appointments'),
              ),
              _QuickAction(
                icon: Icons.favorite_border_rounded,
                label: 'Mes favoris',
                onTap: () => context.go('/favorites'),
              ),
              _QuickAction(
                icon: Icons.history_rounded,
                label: 'Historique',
                onTap: () => context.push('/appointments?tab=history'),
              ),
              _QuickAction(
                icon: Icons.phone_outlined,
                label: 'Contacter le salon',
                onTap: () => context.push('/contact'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _SalonCard(),
          const SizedBox(height: 14),
          FloraCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < _tiles.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1),
                  _Tile(
                    icon: _tiles[i].icon,
                    title: _tiles[i].label,
                    onTap: () => context.push(_tiles[i].route),
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

class _MoreTile {
  const _MoreTile(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: FloraColors.blush,
            shape: BoxShape.circle,
          ),
          child: name == null
              ? const Icon(Icons.person_rounded,
                  size: 40, color: FloraColors.burgundy)
              : Text(
                  name!.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: FloraColors.burgundy,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name == null
                    ? 'Bonjour !'
                    : 'Bonjour ${name!.split(' ').first} !',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: FloraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name == null
                    ? 'Votre nom apparaîtra après votre premier rendez-vous'
                    : "Belle journée à vous aujourd'hui !",
                style: const TextStyle(
                  fontSize: 14,
                  color: FloraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: FloraColors.burgundy, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FloraColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalonCard extends ConsumerWidget {
  const _SalonCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[FloraColors.blushLight, FloraColors.blush],
        ),
        borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.location_on_rounded,
                  color: FloraColors.burgundy, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Flora Hair · Abidjan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: FloraColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Lun – Mer : 9h – 19h · Jeu – Ven : 9h – 20h\nSam : 8h – 18h · Dim : fermé',
            style: TextStyle(fontSize: 13, color: FloraColors.textPrimary),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ref.read(whatsappServiceProvider).openChat(
                  message: 'Bonjour Flora Hair, ',
                ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: FloraColors.textPrimary,
              minimumSize: const Size(0, 42),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('WhatsApp'),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: FloraColors.burgundy),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: FloraColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: FloraColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
