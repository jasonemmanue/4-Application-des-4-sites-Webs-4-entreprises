import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/coach_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/section_title.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider((category: null, level: null)));
    final coaches = ref.watch(coachesProvider);
    final reviews = ref.watch(reviewsProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(activitiesProvider);
          ref.invalidate(coachesProvider);
          ref.invalidate(reviewsProvider);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: _KpiRow()),
            SliverToBoxAdapter(
              child: SectionTitle(
                title: 'Activites vedettes',
                action: 'Tout voir',
                onAction: () => context.go('/activities'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: activities.when(
                  data: (list) {
                    final display = list.take(6).toList();
                    if (display.isEmpty) {
                      return const Center(
                        child: Text('Aucune activite pour le moment.',
                            style: TextStyle(color: AppColors.darkMuted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: display.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 240,
                        child: ActivityCard(
                          activity: display[i],
                          onTap: () =>
                              context.push('/activities/${display[i].slug}'),
                        ),
                      ),
                    );
                  },
                  loading: () => const LoadingState(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: _CtaCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: SectionTitle(title: 'Nos coachs')),
            SliverToBoxAdapter(
              child: coaches.when(
                data: (list) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: list
                        .take(3)
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CoachCard(coach: c),
                            ))
                        .toList(),
                  ),
                ),
                loading: () => const LoadingState(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SectionTitle(title: 'Ils temoignent')),
            SliverToBoxAdapter(
              child: reviews.when(
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => Container(
                        width: 280,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (j) => Icon(
                                  Icons.star,
                                  color: j < list[i].rating
                                      ? AppColors.primary
                                      : AppColors.darkBorder,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                list[i].comment ?? '',
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                            Text('- ${list[i].authorName}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(height: 100, child: LoadingState()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, AppColors.darkLighter, Color(0xFF223046)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: const Text('ESLIE SPORT',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 14),
          const Text('Parce que le corps',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
          const Text('a besoin de sport.',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
          const SizedBox(height: 14),
          const Text(
            'Rejoignez la salle de reference a Blaukauss et transformez votre corps avec nos coachs certifies.',
            style: TextStyle(color: AppColors.darkMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/subscriptions'),
                  icon: const Icon(Icons.card_membership),
                  label: const Text('S\'abonner'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/activities'),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Activites'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('500+', 'Adherents'),
      ('30+', 'Cours / sem'),
      ('8', 'Coachs'),
      ('6j/7', 'Ouvert'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: items
            .map((e) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      children: [
                        Text(e.$1,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            )),
                        const SizedBox(height: 2),
                        Text(e.$2,
                            style: const TextStyle(
                                color: AppColors.darkMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pret a demarrer ?',
              style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'Reservez votre premiere seance et payez seulement 50% en ligne.',
            style: TextStyle(color: AppColors.dark, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.go('/schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Voir le planning'),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone, color: AppColors.dark, size: 14),
              const SizedBox(width: 6),
              Text(ApiConfig.contactPhoneDisplay,
                  style: const TextStyle(
                      color: AppColors.dark, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
