import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/service.dart';
import '../../services/providers.dart';
import '../../widgets/catalog_card.dart';
import '../../widgets/category_pills.dart';
import '../../widgets/search_bar_pill.dart';
import '../../widgets/section_header_row.dart';

/// Écran d'accueil redessiné en style catalogue mobile (Airbnb-like) :
///
/// - barre de recherche « pill » en haut (autocomplétion en bottom-sheet)
/// - pastilles catégorie (Tout / Coiffure / Beauté / Formations)
/// - rangée horizontale « Nos prestations phares » (grandes cartes)
/// - rangée horizontale « Notre équipe » (portraits)
/// - grille galerie (2 col)
/// - CTA en bas
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _pill = 0;

  static const _pills = <CategoryPillItem>[
    CategoryPillItem(label: 'Tout', icon: Icons.public),
    CategoryPillItem(label: 'Coiffure', icon: Icons.spa_outlined),
    CategoryPillItem(label: 'Beauté', icon: Icons.brush_outlined),
    CategoryPillItem(label: 'Formations', icon: Icons.school_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final team = ref.watch(teamProvider);
    final gallery = ref.watch(galleryProvider);
    final articles = ref.watch(articlesProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Barre de recherche pill : ouvre la modale d'autocomplétion.
          const SearchBarPill(),

          // Rangée de pastilles catégorie
          CategoryPills(
            items: _pills,
            selectedIndex: _pill,
            onChanged: (i) {
              setState(() => _pill = i);
              // Routage cohérent avec la sélection.
              switch (i) {
                case 3:
                  context.go('/more'); // Formations vivent dans "Plus"
                  break;
                case 1:
                case 2:
                  context.go('/services');
                  break;
                default:
                  break;
              }
            },
          ),

          // ── Prestations phares ─────────────────────────────
          SectionHeaderRow(
            title: 'Nos prestations phares',
            onSeeAll: () => context.go('/services'),
          ),
          services.when(
            data: (list) => _horizontalCarousel(
              list.take(6).toList(),
              (s) => CatalogCard(
                title: s.name,
                imageUrl: s.imageUrl,
                metaLine: s.formattedPrice(),
                ratingLine: _serviceDuration(s),
                badge: (s.priceMax != null || s.priceFrom) ? 'Sur mesure' : null,
                onTap: () => context.go('/services/${s.slug}'),
              ),
            ),
            loading: () => const _RowLoader(),
            error: (e, _) => _errorTile('Impossible de charger les prestations'),
          ),

          // ── Coiffeuses ─────────────────────────────────────
          SectionHeaderRow(
            title: 'Rencontrez notre équipe',
            subtitle: 'Choisissez votre coiffeuse pour votre prochain rendez-vous.',
            onSeeAll: () => context.go('/team'),
          ),
          team.when(
            data: (list) => _horizontalCarousel(
              list,
              (m) => CatalogCard(
                title: m.name,
                imageUrl: m.photoUrl,
                metaLine: (m.specialties.isNotEmpty ? m.specialties.first : 'Coiffeuse'),
                ratingLine: null,
                imageAspectRatio: 3 / 4,
                width: 180,
                onTap: () => context.go('/booking'),
              ),
              itemHeight: 320,
            ),
            loading: () => const _RowLoader(),
            error: (e, _) => _errorTile("Impossible de charger l'équipe"),
          ),

          // ── Galerie ─────────────────────────────────────────
          SectionHeaderRow(
            title: 'Réalisations récentes',
            onSeeAll: () => context.go('/gallery'),
          ),
          gallery.when(
            data: (list) {
              final display = list.take(4).toList();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: display.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, i) {
                    final title = display[i].title;
                    return CatalogCard(
                      title: (title == null || title.isEmpty)
                          ? 'Réalisation'
                          : title,
                      imageUrl: display[i].imageUrl,
                      metaLine: display[i].tags.isNotEmpty
                          ? display[i].tags.first
                          : '',
                      onTap: () => context.go('/gallery'),
                    );
                  },
                ),
              );
            },
            loading: () => const _RowLoader(),
            error: (e, _) => const SizedBox.shrink(),
          ),

          // ── Articles ────────────────────────────────────────
          SectionHeaderRow(
            title: 'Conseils beauté',
            subtitle: 'Nos derniers articles pour prendre soin de vos cheveux.',
            onSeeAll: () => context.go('/articles'),
          ),
          articles.when(
            data: (list) => _horizontalCarousel(
              list.take(6).toList(),
              (a) => CatalogCard(
                title: a.title,
                imageUrl: a.coverUrl,
                metaLine: a.excerpt,
                imageAspectRatio: 4 / 3,
                width: 260,
                onTap: () => context.go('/articles/${a.slug}'),
              ),
              itemHeight: 280,
            ),
            loading: () => const _RowLoader(),
            error: (e, _) => const SizedBox.shrink(),
          ),

          // Pied de page — bandeau CTA plein
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: FloraColors.goldGradient,
                borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Prête à briller ?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Réservez votre prochain rendez-vous en quelques minutes.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: FloraColors.textPrimary,
                    ),
                    onPressed: () => context.go('/booking'),
                    child: const Text('Prendre rendez-vous'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static String _serviceDuration(Service s) {
    final m = s.durationMinutes;
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h$r';
  }

  Widget _horizontalCarousel<T>(
    List<T> items,
    Widget Function(T) builder, {
    double itemHeight = 260,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => builder(items[i]),
      ),
    );
  }

  Widget _errorTile(String message) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message,
            style: const TextStyle(color: FloraColors.textSecondary)),
      );
}

class _RowLoader extends StatelessWidget {
  const _RowLoader();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
}
