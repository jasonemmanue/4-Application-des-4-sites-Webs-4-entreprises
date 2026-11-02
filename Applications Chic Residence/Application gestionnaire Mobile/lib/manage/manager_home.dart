import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../providers/providers.dart' show currentUserProvider;
import '../widgets/notifications.dart';
import '../widgets/ui.dart';
import 'bookings_screen.dart';
import 'contacts_screen.dart';
import 'format.dart';
import 'providers.dart';

/// Accueil du gérant : arrivées et départs du jour, demandes en attente,
/// messages. Rechargé tout seul (réseau, notifications, toutes les 30 s).
class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final bookings = ref.watch(bookingsProvider);
    final titles = ref.watch(residenceTitlesProvider).valueOrNull ?? const {};
    final today = DateTime.now();
    bool sameDay(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    return AutoRefresh(
      refresh: (ref) {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(bookingsProvider);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(bookingsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                Row(
                  children: [
                    Image.asset('assets/branding/logo-full.png',
                        height: 58, semanticLabel: 'Chic Résidence Meublée'),
                    const Spacer(),
                    NotificationBell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const NotificationsScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Bonjour ${user?.firstName ?? ''} !',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Accueil, logements et réservations',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                stats.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => ErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(dashboardStatsProvider),
                  ),
                  data: (s) => TwoColumns(
                    children: [
                      StatTile(
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        value: '${s.pendingBookings}',
                        label: 'Demandes en attente',
                        onTap: () => context.go('/m/bookings'),
                      ),
                      StatTile(
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        value: '${s.occupancyRate.round()} %',
                        label: 'Occupation sur 30 jours',
                      ),
                      StatTile(
                        icon: Icons.mail_outline_rounded,
                        color: AppColors.primary,
                        value: '${s.unreadContacts}',
                        label: 'Messages non lus',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ContactsScreen())),
                      ),
                      StatTile(
                        icon: Icons.villa_outlined,
                        color: AppColors.info,
                        value: '${s.activeResidences}',
                        label: 'Logements en ligne',
                        onTap: () => context.go('/m/residences'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ...bookings.maybeWhen(
                  data: (page) {
                    final arrivals = page.items
                        .where((b) =>
                            b.status == 'confirmed' && sameDay(b.checkIn))
                        .toList();
                    final departures = page.items
                        .where((b) =>
                            (b.status == 'confirmed' ||
                                b.status == 'completed') &&
                            sameDay(b.checkOut))
                        .toList();
                    return [
                      SectionTitle('Arrivées du jour (${arrivals.length})'),
                      if (arrivals.isEmpty)
                        const Panel(
                          child: Text('Aucune arrivée aujourd\'hui.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      for (final b in arrivals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BookingTile(
                              booking: b,
                              residence: titles[b.residenceId] ?? 'Logement'),
                        ),
                      const SizedBox(height: 14),
                      SectionTitle('Départs du jour (${departures.length})'),
                      if (departures.isEmpty)
                        const Panel(
                          child: Text('Aucun départ aujourd\'hui.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      for (final b in departures)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Panel(
                            child: Text(
                              '${titles[b.residenceId] ?? 'Logement'} · ${b.guestName} · ${fcfa(b.total)}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ),
                        ),
                    ];
                  },
                  orElse: () => const <Widget>[],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
