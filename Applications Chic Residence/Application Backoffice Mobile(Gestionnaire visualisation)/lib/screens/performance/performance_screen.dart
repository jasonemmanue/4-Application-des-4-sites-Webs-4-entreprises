import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/theme.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Donnees mock — a remplacer par un appel API /staff/stats/performance
    final data = <double>[3, 5, 4, 7, 6, 8, 6, 9, 7, 10, 8, 12, 10];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Performance globale',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Taches terminees / jour — 30 derniers jours',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i]),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Top agents', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800)),
              ),
              title: Text('Agent ${i + 1}'),
              subtitle: Text('${30 - i * 4} taches • ${95 - i * 3}% validation'),
              trailing: Icon(Icons.emoji_events_rounded,
                  color: [
                    const Color(0xFFFFD700),
                    const Color(0xFFC0C0C0),
                    const Color(0xFFCD7F32),
                  ][i]),
            ),
          ),
        ),
      ],
    );
  }
}
