import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _fcfa = NumberFormat('#,##0', 'fr_FR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final bookings = ref.watch(recentBookingsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentBookingsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Vue d\'ensemble',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          stats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString(),
                style: const TextStyle(color: AppColors.error)),
            data: (s) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  icon: Icons.villa_outlined,
                  color: AppColors.primary,
                  label: 'Residences',
                  value: '${s.residencesCount}',
                ),
                StatCard(
                  icon: Icons.calendar_month_outlined,
                  color: AppColors.info,
                  label: 'Reservations (mois)',
                  value: '${s.bookingsMonth}',
                ),
                StatCard(
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  label: 'Occupation',
                  value: '${(s.occupancyRate * 100).round()}%',
                ),
                StatCard(
                  icon: Icons.payments_outlined,
                  color: AppColors.accent,
                  label: 'Revenus (mois)',
                  value: '${_fcfa.format(s.revenueMonth).replaceAll(',', ' ')} F',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Suivi terrain',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          stats.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  icon: Icons.cleaning_services_rounded,
                  color: AppColors.info,
                  label: 'Nettoyages en cours',
                  value: '${s.cleaningInProgress}',
                ),
                StatCard(
                  icon: Icons.rule_rounded,
                  color: AppColors.warning,
                  label: 'A controler',
                  value: '${s.cleaningToControl}',
                ),
                StatCard(
                  icon: Icons.verified_rounded,
                  color: AppColors.success,
                  label: 'Validation 1er passage',
                  value: '${(s.firstPassValidationRate * 100).round()}%',
                ),
                StatCard(
                  icon: Icons.timer_outlined,
                  color: AppColors.primary,
                  label: 'Temps moyen preparation',
                  value: '${s.avgPreparationMinutes} min',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Reservations recentes',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          bookings.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(e.toString()),
            data: (list) {
              if (list.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Aucune reservation recente')),
                  ),
                );
              }
              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = list[i];
                    return ListTile(
                      title: Text(b.residenceName),
                      subtitle: Text(
                          '${b.guestName} • ${DateFormat('dd/MM').format(b.checkIn)} - ${DateFormat('dd/MM').format(b.checkOut)}'),
                      trailing: Text(
                          '${_fcfa.format(b.totalAmount).replaceAll(',', ' ')} F',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
