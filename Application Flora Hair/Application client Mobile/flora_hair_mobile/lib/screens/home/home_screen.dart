import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/gallery_item.dart';
import '../../models/service.dart';
import '../../services/appointments.dart';
import '../../services/favorites.dart';
import '../../services/providers.dart';
import '../../widgets/deposit_notice.dart';
import '../../widgets/flora_ui.dart';
import '../../widgets/search_bar_pill.dart';

/// Accueil : logo du salon en haut à gauche, accroche, recherche, catégories,
/// bandeau des tendances, prestations, inspirations, équipe et conseils.
/// Tout le contenu vient de l'API, donc de l'administration du site.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final services = ref.watch(servicesProvider);
    final gallery = ref.watch(galleryProvider);
    final team = ref.watch(teamProvider);
    final articles = ref.watch(articlesProvider);

    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: FloraColors.heroGradient),
            child: SizedBox.expand(),
          ),
        ),
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(categoriesProvider);
              ref.invalidate(galleryProvider);
              ref.invalidate(teamProvider);
              ref.invalidate(articlesProvider);
              ref.invalidate(reviewsProvider);
              ref.invalidate(servicesProvider);
              await ref.read(servicesProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: <Widget>[
                const _HomeHeader(),
                const _Hero(),
                const SearchBarPill(),
                categories.maybeWhen(
                  data: (cats) => SizedBox(
                    height: 88,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => _CategoryBubble(
                        label: cats[i].name,
                        icon: categoryIcon(cats[i].slug),
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state =
                              cats[i].slug;
                          context.go('/services');
                        },
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox(height: 8),
                ),
                gallery.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : _TrendsBanner(items: items.take(4).toList()),
                  orElse: () => const SizedBox.shrink(),
                ),
                FloraSectionHeader(
                  title: 'Nos prestations',
                  onSeeAll: () => context.go('/services'),
                ),
                services.when(
                  data: (list) => SizedBox(
                    height: 172,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _withPhotoFirst(list).take(8).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _ServiceTile(service: _withPhotoFirst(list)[i]),
                    ),
                  ),
                  loading: () => const _RowLoader(height: 172),
                  error: (_, __) => _RetryRow(
                    message: 'Impossible de charger les prestations.',
                    onRetry: () => ref.invalidate(servicesProvider),
                  ),
                ),
                gallery.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: <Widget>[
                            FloraSectionHeader(
                              title: 'Inspirations',
                              onSeeAll: () => context.push('/gallery'),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.95,
                                children: <Widget>[
                                  for (final item in items.take(4))
                                    _InspirationTile(item: item),
                                ],
                              ),
                            ),
                          ],
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                team.maybeWhen(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FloraSectionHeader(
                              title: 'Notre équipe',
                              onSeeAll: () => context.push('/team'),
                            ),
                            SizedBox(
                              height: 116,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, i) => InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => context.push('/team'),
                                  child: SizedBox(
                                    width: 78,
                                    child: Column(
                                      children: <Widget>[
                                        ClipOval(
                                          child: SizedBox(
                                            width: 72,
                                            height: 72,
                                            child: FloraImage(
                                              url: list[i].photoUrl,
                                              label: list[i].name,
                                              icon: Icons.person_outline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          list[i].name.split(' ').first,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: FloraColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                articles.maybeWhen(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: <Widget>[
                            FloraSectionHeader(
                              title: 'Conseils beauté',
                              onSeeAll: () => context.push('/articles'),
                            ),
                            SizedBox(
                              height: 190,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: list.take(6).length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) => SizedBox(
                                  width: 230,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                        FloraTheme.cardRadius),
                                    onTap: () => context
                                        .push('/articles/${list[i].slug}'),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                FloraTheme.cardRadius),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: FloraImage(
                                                url: list[i].coverUrl,
                                                label: list[i].title,
                                                alignment: Alignment.center,
                                                icon: Icons.menu_book_outlined,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          list[i].title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                            color: FloraColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        // Pastille flottante : un tap ouvre le pop-up sur l'acompte de 50 %.
        const Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Center(child: DepositNoticePill()),
        ),
      ],
    );
  }

  /// Les prestations avec photo d'abord : c'est la première impression.
  static List<Service> _withPhotoFirst(List<Service> list) {
    bool hasPhoto(Service s) => (s.imageUrl ?? '').trim().isNotEmpty;
    return <Service>[
      ...list.where(hasPhoto),
      ...list.where((s) => !hasPhoto(s)),
    ];
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming =
        ref.watch(appointmentsProvider).where((a) => a.isUpcoming).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
      child: Row(
        children: <Widget>[
          Image.asset(
            'assets/branding/logo_mark.png',
            width: 46,
            height: 46,
            semanticLabel: 'Logo Flora Hair',
          ),
          const SizedBox(width: 10),
          Text(
            'FLORA HAIR',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: FloraColors.burgundy,
            ),
          ),
          const Spacer(),
          // Pastille réelle : le nombre de rendez-vous à venir sur cet appareil.
          IconButton(
            tooltip: 'Mes rendez-vous',
            onPressed: () => context.push('/appointments'),
            icon: Badge(
              isLabelVisible: upcoming > 0,
              label: Text('$upcoming'),
              backgroundColor: FloraColors.danger,
              child: const Icon(Icons.notifications_none_rounded,
                  color: FloraColors.textPrimary, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Révélez votre',
            style: GoogleFonts.dmSans(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.6,
              color: FloraColors.textPrimary,
            ),
          ),
          Text(
            'beauté.',
            style: GoogleFonts.allura(
              fontSize: 60,
              height: 1.05,
              color: FloraColors.gold,
            ),
          ),
          Text(
            'Votre salon de coiffure & beauté à Abidjan',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: FloraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 66,
        child: Column(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: FloraColors.blush,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: FloraColors.burgundy, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w500,
                color: FloraColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau « Les tendances du moment », alimenté par la galerie de l'admin.
class _TrendsBanner extends StatefulWidget {
  const _TrendsBanner({required this.items});
  final List<GalleryItem> items;

  @override
  State<_TrendsBanner> createState() => _TrendsBannerState();
}

class _TrendsBannerState extends State<_TrendsBanner> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
        child: SizedBox(
          height: 158,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              PageView.builder(
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => FloraImage(
                  url: widget.items[i].imageUrl,
                  label: widget.items[i].title,
                  alignment: const Alignment(0, -0.4),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const <double>[0, 0.55, 1],
                      colors: <Color>[
                        FloraColors.burgundyDark.withValues(alpha: 0.92),
                        FloraColors.burgundy.withValues(alpha: 0.62),
                        FloraColors.burgundy.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 20,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Les tendances\ndu moment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => context.push('/gallery'),
                      style: FilledButton.styleFrom(
                        backgroundColor: FloraColors.gold,
                        foregroundColor: FloraColors.cocoa,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Découvrir  →'),
                    ),
                  ],
                ),
              ),
              if (widget.items.length > 1)
                Positioned(
                  right: 14,
                  bottom: 12,
                  child: IgnorePointer(
                    child: Row(
                      children: <Widget>[
                        for (int i = 0; i < widget.items.length; i++)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/services/${service.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  child: FloraImage(url: service.imageUrl, label: service.name),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              service.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FloraColors.textPrimary,
              ),
            ),
            Text(
              service.shortPrice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: FloraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspirationTile extends StatelessWidget {
  const _InspirationTile({required this.item});
  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: () => context.push('/gallery'),
            child: FloraImage(url: item.imageUrl, label: item.title),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: FavoriteButton(
              favoriteKey: favoriteGalleryKey(item.id),
              label: item.title ?? 'réalisation',
            ),
          ),
        ],
      ),
    );
  }
}

class _RowLoader extends StatelessWidget {
  const _RowLoader({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
}

class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: FloraColors.textSecondary)),
            ),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
}
