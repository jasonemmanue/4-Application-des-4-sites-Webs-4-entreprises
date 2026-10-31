import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Chiffres réels de l'API (l'ancien écran affichait des données inventées).
class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  static const _periods = {'7d': '7 jours', '30d': '30 jours', '90d': '90 jours'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(performancePeriodProvider);
    final points = ref.watch(performanceProvider);
    final overview = ref.watch(overviewProvider).valueOrNull;
    final staff = ref.watch(staffProvider).valueOrNull ?? const <StaffMember>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (overview != null) ...[
            TwoColumns(
              children: [
                StatTile(
                  icon: Icons.verified_rounded,
                  color: AppColors.success,
                  value: '${overview.validated}',
                  label: 'Tâches validées',
                ),
                StatTile(
                  icon: Icons.rule_rounded,
                  color: AppColors.primary,
                  value: '${overview.cleaned}',
                  label: 'En attente de contrôle',
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          SectionTitle(
            'Nettoyages terminés',
            action: DropdownButton<String>(
              value: period,
              underline: const SizedBox.shrink(),
              items: [
                for (final e in _periods.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => ref
                  .read(performancePeriodProvider.notifier)
                  .state = v ?? period,
            ),
          ),
          Panel(
            child: SizedBox(
              height: 200,
              child: points.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(error: e),
                data: (list) {
                  if (list.every((p) => p.completed == 0)) {
                    return const EmptyState(
                      icon: Icons.insights_rounded,
                      title: 'Aucun nettoyage sur cette période',
                    );
                  }
                  return LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 28),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < list.length; i++)
                              FlSpot(i.toDouble(), list[i].completed.toDouble()),
                          ],
                          color: AppColors.primary,
                          barWidth: 3,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Par agent'),
          if (staff.where((s) => s.role == StaffRole.agent).isEmpty)
            const Panel(
              child: EmptyState(
                icon: Icons.groups_outlined,
                title: 'Aucun agent',
              ),
            ),
          for (final s in staff.where((s) => s.role == StaffRole.agent))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AgentRow(member: s),
            ),
        ],
      ),
    );
  }
}

class _AgentRow extends ConsumerWidget {
  const _AgentRow({required this.member});
  final StaffMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(staffStatsProvider(member.id)).valueOrNull;
    return Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (st != null)
                  Text(
                    '${st.completed} nettoyages · '
                    '${st.averageMinutes == null ? '-' : '${st.averageMinutes!.round()} min'} en moyenne',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          if (st?.firstPassRate != null)
            StatusPill(
              label: '${(st!.firstPassRate! * 100).round()} %',
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}
