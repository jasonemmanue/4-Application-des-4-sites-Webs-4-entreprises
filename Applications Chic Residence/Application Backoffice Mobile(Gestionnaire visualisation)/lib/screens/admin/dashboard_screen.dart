import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';
import 'bookings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final overview = ref.watch(overviewProvider);
    final titles = ref.watch(residenceTitlesProvider).valueOrNull ?? const {};

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(overviewProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Row(
                children: [
                  Image.asset('assets/branding/logo-full.png',
                      height: 58, semanticLabel: 'Chic Résidence Meublée'),
                  const Spacer(),
                  const StatusPill(
                      label: 'Administration', color: AppColors.navy),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Bonjour ${(admin?.fullName ?? '').split(' ').first} !',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Text(
                'Vos logements et réservations en un coup d\'œil',
                style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              stats.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(dashboardStatsProvider),
                ),
                data: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TwoColumns(
                      children: [
                        StatTile(
                          icon: Icons.villa_outlined,
                          color: AppColors.primary,
                          value: '${s.activeResidences}',
                          label: 'Logements en ligne',
                          onTap: () => context.go('/residences'),
                        ),
                        StatTile(
                          icon: Icons.pending_actions_rounded,
                          color: AppColors.warning,
                          value: '${s.pendingBookings}',
                          label: 'Réservations en attente',
                          onTap: () => context.go('/bookings'),
                        ),
                        StatTile(
                          icon: Icons.trending_up_rounded,
                          color: AppColors.success,
                          value: '${s.occupancyRate.round()} %',
                          label:
                              'Occupation (${s.soldNights} nuits sur ${s.offeredNights})',
                        ),
                        StatTile(
                          icon: Icons.payments_outlined,
                          color: AppColors.info,
                          value: fcfa(s.totalRevenue),
                          label: 'Revenus confirmés',
                        ),
                        StatTile(
                          icon: Icons.rate_review_outlined,
                          color: AppColors.accent,
                          value: '${s.pendingReviews}',
                          label: 'Avis à modérer',
                          onTap: () => context.push('/reviews'),
                        ),
                        StatTile(
                          icon: Icons.mail_outline_rounded,
                          color: AppColors.primary,
                          value: '${s.unreadContacts}',
                          label: 'Messages non lus',
                          onTap: () => context.push('/contacts'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const SectionTitle('Suivi terrain'),
                    overview.maybeWhen(
                      data: (o) => TwoColumns(
                        children: [
                          StatTile(
                            icon: Icons.cleaning_services_rounded,
                            color: AppColors.info,
                            value: '${o.pending + o.inProgress}',
                            label: 'Nettoyages à faire ou en cours',
                            onTap: () => context.go('/cleaning'),
                          ),
                          StatTile(
                            icon: Icons.rule_rounded,
                            color: AppColors.primary,
                            value: '${o.cleaned}',
                            label: 'À contrôler',
                            onTap: () => context.go('/cleaning'),
                          ),
                        ],
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 22),
                    SectionTitle(
                      'Prochaines arrivées',
                      action: TextButton(
                        onPressed: () => context.go('/bookings'),
                        child: const Text('Voir tout'),
                      ),
                    ),
                    if (s.upcoming.isEmpty)
                      const Panel(
                        child: EmptyState(
                          icon: Icons.event_available_rounded,
                          title: 'Aucune arrivée prévue',
                        ),
                      )
                    else
                      for (final b in s.upcoming)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BookingTile(
                            booking: b,
                            residence: titles[b.residenceId] ?? 'Logement',
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
