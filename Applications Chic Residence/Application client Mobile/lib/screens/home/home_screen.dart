import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/other_models.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../services/residence_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/fees_notice.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/search_bar_field.dart';
import '../../widgets/state_views.dart';

/// Écran « Explorer » — refonte compacte inspirée d'Airbnb.
///
/// Recherche → chips catégorie → bandeau de confiance → carrousel populaire →
/// « Pourquoi CHIC RESIDENCE » → grille 2 colonnes → avis voyageurs →
/// « Comment ça marche » → proposer son logement. Des cadres plus petits et
/// plus d'informations essentielles, comme le côté visiteur du site web.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final filters = ref.watch(filtersProvider);
    final async = ref.watch(residencesProvider);

    final pillVisible = ref.watch(feesNoticeVisibleProvider);
    final bottomClearance = context.bottomInset(pillVisible ? 64 : 0);

    return Scaffold(
      backgroundColor: t.surface,
      // Pas de SafeArea en haut : le bandeau héros remonte sous la barre
      // d'état pour un rendu immersif (il réserve lui-même la marge système).
      body: Stack(
        children: [
          _buildScroll(context, ref, filters, async, bottomClearance),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
            child: const Center(child: FeesNoticePill()),
          ),
        ],
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
          child: _HeroHeader(onSearchTap: () => context.push('/search')),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
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
              const SliverFillRemaining(
            hasScrollBody: true,
            child: LoadingCards(count: 3),
          ),
          // Remplit l'espace restant et centre le message : sinon l'erreur
          // s'accroche sous les chips et laisse un grand vide blanc jusqu'en bas.
          error: (e, _) => SliverFillRemaining(
            hasScrollBody: false,
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
      return const SliverFillRemaining(
        hasScrollBody: false,
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
    final topCount = list.length >= 12 ? 6 : (list.length + 1) ~/ 2;
    final top = ranked.take(topCount).toList();

    void seeAll() {
      ref.read(filtersProvider.notifier).state = const ResidenceFilters();
      context.push('/search');
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 4),
        _StatsStrip(list: list),
        const SizedBox(height: 20),

        // ── Résidences populaires (carrousel compact) ──────────────────
        _SectionHeading(
          title: 'Résidences populaires',
          onSeeAll: seeAll,
        ),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ResidenceCard(
              residence: top[i],
              width: 168,
              onTap: () => context.push('/residence/${top[i].slug}'),
            ),
          ),
        ),

        const SizedBox(height: 28),
        const _WhyChic(),

        const SizedBox(height: 28),
        _SectionHeading(
          title: 'Toutes nos résidences',
          subtitle:
              "Séjournez chez CHIC RESIDENCE, à deux pas de l'Ivoire Trade Center.",
          onSeeAll: seeAll,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ResidenceGrid(
            list: ranked,
            onTap: (r) => context.push('/residence/${r.slug}'),
          ),
        ),

        const SizedBox(height: 28),
        const _ReviewsSection(),

        const SizedBox(height: 28),
        const _HowItWorks(),

        const SizedBox(height: 24),
        const _ProposeCta(),

        const SizedBox(height: 12),
      ]),
    );
  }
}

/// Bandeau héros — la grande zone de marque de l'écran (façon « une seule
/// grande zone colorée par écran »). Dégradé rouge/orange CHIC RESIDENCE
/// remontant sous la barre d'état, surtitre, slogan, emplacement, puis la
/// pilule de recherche blanche posée dessus : élégant et immédiatement
/// orienté « trouvez votre résidence ».
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onSearchTap});
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33991B1B),
            blurRadius: 28,
            spreadRadius: -6,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHIC RESIDENCE MEUBLÉE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre chez-vous,\nailleurs.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Dans le dos de l'Ivoire Trade Center · Abidjan",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SearchBarField(onTap: onSearchTap),
        ],
      ),
    );
  }
}

/// Bandeau de chiffres clés, dérivé des résidences déjà chargées (aucun appel
/// API supplémentaire) : nombre de logements, capacité totale, note moyenne.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.list});
  final List<Residence> list;

  @override
  Widget build(BuildContext context) {
    final capacity = list.fold<int>(0, (s, r) => s + r.capacity);
    final rated = list.where((r) => r.reviewsCount > 0).toList();
    final avg = rated.isEmpty
        ? null
        : rated.fold<double>(0, (s, r) => s + r.rating) / rated.length;

    final items = <(IconData, String, String)>[
      (Icons.apartment_rounded, '${list.length}', 'logements'),
      (Icons.groups_rounded, '$capacity', 'personnes'),
      if (avg != null)
        (Icons.star_rounded, avg.toStringAsFixed(1), 'note moyenne'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: items[i].$1,
                value: items[i].$2,
                label: items[i].$3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: AppShadows.soft(t),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Grille 2 colonnes de cadres compacts. Construite ligne par ligne (deux
/// cards par Row) : chaque card prend sa hauteur naturelle, aucun risque de
/// débordement contrairement à un GridView à ratio figé.
class _ResidenceGrid extends StatelessWidget {
  const _ResidenceGrid({required this.list, required this.onTap});
  final List<Residence> list;
  final ValueChanged<Residence> onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < list.length; i += 2) {
      final a = list[i];
      final b = (i + 1 < list.length) ? list[i + 1] : null;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ResidenceCard(residence: a, onTap: () => onTap(a)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: b == null
                  ? const SizedBox()
                  : ResidenceCard(residence: b, onTap: () => onTap(b)),
            ),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// « Pourquoi CHIC RESIDENCE » — 4 atouts en petits cadres (comme la bande de
/// features du site web, adaptée au mobile).
class _WhyChic extends StatelessWidget {
  const _WhyChic();

  static const _items = <(IconData, String, String)>[
    (
      Icons.verified_user_rounded,
      'Acompte 50 %',
      'Réservez en réglant la moitié, le reste à l\'arrivée.'
    ),
    (
      Icons.bolt_rounded,
      'Réponse rapide',
      'Confirmation et assistance sur WhatsApp.'
    ),
    (
      Icons.cleaning_services_rounded,
      'Qualité vérifiée',
      'Logements préparés et contrôlés entre chaque séjour.'
    ),
    (
      Icons.location_on_rounded,
      'Emplacement idéal',
      'À deux pas de l\'Ivoire Trade Center, Abidjan.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Pourquoi CHIC RESIDENCE'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _WhyTile(
                          icon: _items[i].$1,
                          title: _items[i].$2,
                          text: _items[i].$3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _WhyTile(
                          icon: _items[i + 1].$1,
                          title: _items[i + 1].$2,
                          text: _items[i + 1].$3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhyTile extends StatelessWidget {
  const _WhyTile(
      {required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: AppShadows.soft(t),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary600),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: t.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// Carrousel « Avis de nos voyageurs » — alimenté par [topReviewsProvider].
/// Masqué tant qu'il n'y a aucun avis (section vide = pas de bruit).
class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topReviewsProvider);
    return async.maybeWhen(
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(title: 'Avis de nos voyageurs'),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _ReviewCard(review: reviews[i]),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: AppShadows.soft(t),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  i < review.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: AppColors.sand500,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              '« ${review.comment} »',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.35),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            review.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// « Comment ça marche » — 3 étapes, reprises de la page d'accueil du site.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = <(String, String, String)>[
    ('1', 'Choisissez', 'Parcourez les résidences et vos dates.'),
    ('2', 'Réservez', 'Payez 50 % d\'acompte en Mobile Money.'),
    ('3', 'Séjournez', 'Recevez l\'adresse et profitez de votre séjour.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Comment ça marche'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final s in _steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary800,
                              AppColors.primary600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.$2,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.$3,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: t.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Encart « Proposer votre logement » → WhatsApp, repris du côté visiteur.
class _ProposeCta extends StatelessWidget {
  const _ProposeCta();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary800, AppColors.primary600],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proposer votre logement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Confiez votre bien meublé à CHIC RESIDENCE et percevez des '
              'revenus supplémentaires. On en parle sur WhatsApp.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary700,
              ),
              onPressed: () => WhatsAppService.send(
                'Bonjour CHIC RESIDENCE, je souhaite proposer mon logement meublé à la location.',
              ),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Discuter sur WhatsApp'),
            ),
          ],
        ),
      ),
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
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (onSeeAll != null)
                Semantics(
                  button: true,
                  label: 'Voir tout',
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onSeeAll,
                      child: Container(
                        width: 36,
                        height: 36,
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
                            size: 17, color: t.textPrimary),
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
