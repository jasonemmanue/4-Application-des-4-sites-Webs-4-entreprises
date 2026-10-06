/// Ecran d'accueil Airbnb-like :
///   * barre de recherche pill flottante (avec autocompletion via un ecran
///     modale plein ecran) ;
///   * chips de categorie horizontales (`Tout`, `Force`, `Cardio`, …) ;
///   * carrousels de cartes carrees pour les activites, formules, etc.,
///   * pastille flottante « Réservez avec 50 % d'acompte » + pop-up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/activity.dart';
import '../../services/providers.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/deposit_notice.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/search_pill.dart';
import '../../widgets/section_title.dart';
import '../../widgets/subscription_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final activities =
        ref.watch(activitiesProvider((category: _category, level: null)));
    final subscriptions = ref.watch(subscriptionsProvider);
    final transformations = ref.watch(featuredTransformationsProvider);
    final coaches = ref.watch(coachesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.textPrimary,
            onRefresh: () async {
              ref.invalidate(activitiesProvider);
              ref.invalidate(subscriptionsProvider);
              ref.invalidate(coachesProvider);
              ref.invalidate(featuredTransformationsProvider);
            },
            child: CustomScrollView(
              slivers: [
                const SliverPadding(padding: EdgeInsets.only(top: 12)),
                const SliverSafeArea(
                  sliver: SliverToBoxAdapter(child: SearchPillTrigger()),
                  bottom: false,
                ),
                SliverToBoxAdapter(
                  child: _CategoryChips(
                    current: _category,
                    onSelect: (c) => setState(() => _category = c),
                  ),
                ),

                // ── Activites populaires ───────────────────────────────
                SliverToBoxAdapter(
                  child: SectionTitle(
                    title: _category == null
                        ? 'Activites populaires a Blaukauss'
                        : 'Activites · $_category',
                    onAction: () => context.go('/activities'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HorizontalCards<Activity>(
                    asyncList: activities,
                    itemBuilder: (a, i) => ActivityCard(
                      activity: a,
                      badgeLabel:
                          i == 0 && _category == null ? 'Favori du club' : null,
                      onTap: () => context.push('/activities/${a.slug}'),
                    ),
                    emptyLabel: 'Aucune activite pour cette categorie.',
                    itemWidth: 220,
                  ),
                ),

                // ── Formules ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SectionTitle(
                    title: 'Formules avantageuses',
                    subtitle:
                        'Payez 50 % en ligne pour reserver, le reste a la salle.',
                    onAction: () => context.go('/subscriptions'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: subscriptions.when(
                    data: (list) {
                      if (list.isEmpty) return const SizedBox.shrink();
                      final display = list.take(4).toList();
                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: display.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 260,
                            child: SubscriptionCard(
                              subscription: display[i],
                              onSubscribe: () => context.push(
                                  '/subscriptions/order/${display[i].id}'),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const SizedBox(height: 160, child: LoadingState()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ── Coachs ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SectionTitle(
                    title: 'Vos coachs certifies',
                    onAction: () => context.push('/more'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: coaches.when(
                    data: (list) {
                      if (list.isEmpty) return const SizedBox.shrink();
                      final display = list.take(6).toList();
                      return SizedBox(
                        height: 170,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: display.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (_, i) => _CoachTile(coach: display[i]),
                        ),
                      );
                    },
                    loading: () =>
                        const SizedBox(height: 140, child: LoadingState()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ── Transformations vedettes ──────────────────────────
                SliverToBoxAdapter(
                  child: SectionTitle(
                    title: 'Ils ont transforme leur corps',
                    onAction: () => context.push('/more'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: transformations.when(
                    data: (list) {
                      if (list.isEmpty) return const SizedBox.shrink();
                      final display = list.take(6).toList();
                      return SizedBox(
                        height: 240,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: display.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => _TransformationTile(
                            memberName: display[i].memberName,
                            duration: display[i].durationText ?? '',
                            beforeUrl: display[i].beforeImageUrl,
                            afterUrl: display[i].afterImageUrl,
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const SizedBox(height: 180, child: LoadingState()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // Pastille flottante — comme « Les prix comprennent tous les
          // frais » d'Airbnb. Un tap ouvre le pop-up explicatif.
          const Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Center(child: DepositNoticePill()),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onSelect;
  const _CategoryChips({required this.current, required this.onSelect});

  static const _cats = <(String? key, String label, IconData icon)>[
    (null, 'Tout', Icons.language),
    ('force', 'Force', Icons.fitness_center),
    ('cardio', 'Cardio', Icons.favorite),
    ('souplesse', 'Souplesse', Icons.self_improvement),
    ('arts martiaux', 'Arts martiaux', Icons.sports_martial_arts),
    ('danse', 'Danse', Icons.music_note),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Hauteur de la pilule (44) + marge pour son ombre portée.
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (key, label, icon) = _cats[i];
          final selected = key == current;
          return _ChipCategory(
            label: label,
            icon: icon,
            selected: selected,
            onTap: () => onSelect(key),
          );
        },
      ),
    );
  }
}

/// Chip pilule — style Airbnb : fond plein, contour, ombre douce. La
/// sélection se lit au contour or épaissi et au fond plus clair.
class _ChipCategory extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChipCategory({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.full),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalCards<T> extends StatelessWidget {
  final AsyncValue<List<T>> asyncList;
  final Widget Function(T item, int index) itemBuilder;
  final String emptyLabel;
  final double itemWidth;
  const _HorizontalCards({
    required this.asyncList,
    required this.itemBuilder,
    required this.emptyLabel,
    this.itemWidth = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemWidth + 76,
      child: asyncList.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(emptyLabel,
                  style: const TextStyle(color: AppColors.textSecondary)),
            );
          }
          final display = list.take(8).toList();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) =>
                SizedBox(width: itemWidth, child: itemBuilder(display[i], i)),
          );
        },
        loading: () => const LoadingState(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  final dynamic coach;
  const _CoachTile({required this.coach});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceSubtle,
              border: Border.all(color: AppColors.border),
              image: coach.photoUrl != null &&
                      (coach.photoUrl as String).isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(coach.photoUrl as String),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: coach.photoUrl == null || (coach.photoUrl as String).isEmpty
                ? const Icon(Icons.person, color: AppColors.textMuted, size: 40)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            coach.name as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((coach.specialties as List).isNotEmpty)
            Text(
              (coach.specialties as List).first.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _TransformationTile extends StatelessWidget {
  final String memberName;
  final String duration;
  final String? beforeUrl;
  final String? afterUrl;
  const _TransformationTile({
    required this.memberName,
    required this.duration,
    required this.beforeUrl,
    required this.afterUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(child: _photo(beforeUrl, 'Avant')),
                  const SizedBox(width: 2),
                  Expanded(child: _photo(afterUrl, 'Apres')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            memberName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (duration.isNotEmpty)
            Text(
              duration,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _photo(String? url, String label) {
    return Container(
      color: AppColors.surfaceSubtle,
      alignment: Alignment.bottomLeft,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceSubtle,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.textMuted))),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
