import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../services/residence_service.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/fees_notice.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/search_bar_field.dart';
import '../../widgets/state_views.dart';

/// Écran « Explorer » — refonte inspirée d'Airbnb.
///
/// Recherche pilulaire → chips catégorie → sections (« Résidences populaires
/// à Abidjan », « Idéales pour votre prochain séjour »).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final filters = ref.watch(filtersProvider);
    final async = ref.watch(residencesProvider);

    // Dégagement supplémentaire tant que la pastille « Aucun frais caché »
    // flotte en bas : la dernière carte ne doit pas finir dessous.
    final pillVisible = ref.watch(feesNoticeVisibleProvider);
    final bottomClearance = context.bottomInset(pillVisible ? 64 : 0);

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildScroll(context, ref, filters, async, bottomClearance),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Center(child: FeesNoticePill()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScroll(
    BuildContext context,
    WidgetRef ref,
    ResidenceFilters filters,
    AsyncValue<List<Residence>> async,
    double bottomClearance,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBarField(onTap: () => context.push('/search')),
          ),
        ),
        SliverToBoxAdapter(
          child: CategoryChips(
            selected: filters.type,
            onSelect: (type) {
              ref.read(filtersProvider.notifier).update(
                    (s) => s.copyWith(
                      type: type,
                      clearType: type == null,
                    ),
                  );
            },
          ),
        ),
        async.when(
          data: (list) => _buildContent(context, ref, list),
          loading: () =>
              const SliverToBoxAdapter(child: LoadingCards(count: 3)),
          error: (e, _) => SliverToBoxAdapter(
            child: ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(residencesProvider),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<Residence> list) {
    if (list.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyView(
          title: 'Aucune résidence',
          description:
              'Essayez de modifier vos filtres ou retirer les catégories.',
        ),
      );
    }

    final ranked = [...list]..sort((a, b) {
        final af = a.isFeatured ? 1 : 0;
        final bf = b.isFeatured ? 1 : 0;
        if (af != bf) return bf - af;
        return b.rating.compareTo(a.rating);
      });
    // Jusqu'à 6 en carrousel, mais jamais tout le catalogue : avec 5
    // logements en production, `take(6)` les prenait tous et la seconde
    // section restait un titre sans contenu.
    final topCount = list.length >= 12 ? 6 : (list.length + 1) ~/ 2;
    final top = ranked.take(topCount).toList();
    final rest = ranked.where((r) => !top.contains(r)).toList();

    // La flèche de chaque section ouvre le catalogue complet, filtres remis
    // à zéro : « voir tout » doit montrer tout, pas la catégorie
    // actuellement sélectionnée.
    void seeAll() {
      ref.read(filtersProvider.notifier).state = const ResidenceFilters();
      context.push('/search');
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 8),
        _SectionHeading(
          title: 'Résidences populaires à Abidjan',
          onSeeAll: seeAll,
        ),
        SizedBox(
          // Carte de 260 px : image carrée 240 + cadre (2 × 10) + 10 + titre
          // (≈ 21) + 3 + prix (≈ 18) + 2 ≈ 317 px. L'ancienne valeur (286)
          // coupait la ligne de prix. `Clip.none` pour garder l'ombre.
          height: 324,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ResidenceCard(
              residence: top[i],
              horizontal: true,
              onTap: () => context.push('/residence/${top[i].slug}'),
            ),
          ),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 28),
          _SectionHeading(
            title: 'Idéales pour votre prochain séjour',
            subtitle:
                "Séjournez chez CHIC RESIDENCE, à deux pas de l'Ivoire Trade Center.",
            onSeeAll: seeAll,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final r in rest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ResidenceCard(
                      residence: r,
                      onTap: () => context.push('/residence/${r.slug}'),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (onSeeAll != null)
                Semantics(
                  button: true,
                  label: 'Voir toutes les résidences',
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onSeeAll,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.surfaceElevated,
                          border: Border.all(color: t.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: t.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 18, color: t.textPrimary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: t.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
