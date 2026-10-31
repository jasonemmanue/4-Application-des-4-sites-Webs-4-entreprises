import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/favorites.dart';
import '../../services/providers.dart';
import '../../widgets/flora_ui.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final services = (ref.watch(servicesProvider).valueOrNull ?? const [])
        .where((s) => favorites.contains(favoriteServiceKey(s.slug)))
        .toList();
    final gallery = (ref.watch(galleryProvider).valueOrNull ?? const [])
        .where((g) => favorites.contains(favoriteGalleryKey(g.id)))
        .toList();
    final empty = services.isEmpty && gallery.isEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Mes favoris',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: FloraColors.textPrimary,
              ),
            ),
          ),
          if (empty)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 72, 32, 0),
              child: Column(
                children: <Widget>[
                  const Icon(Icons.favorite_border_rounded,
                      size: 56, color: FloraColors.blush),
                  const SizedBox(height: 14),
                  const Text(
                    'Aucun favori pour le moment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FloraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Touchez le cœur sur une prestation ou une inspiration '
                    'pour la retrouver ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FloraColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => context.go('/services'),
                    child: const Text('Voir les prestations'),
                  ),
                ],
              ),
            ),
          if (services.isNotEmpty) ...<Widget>[
            const FloraSectionHeader(
              title: 'Prestations',
              padding: EdgeInsets.fromLTRB(20, 8, 12, 10),
            ),
            for (final s in services)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: FloraCard(
                  padding: const EdgeInsets.all(10),
                  onTap: () => context.push('/services/${s.slug}'),
                  child: Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: FloraImage(url: s.imageUrl, label: s.name),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              s.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: FloraColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.formattedPrice(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: FloraColors.burgundy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FavoriteButton(
                        favoriteKey: favoriteServiceKey(s.slug),
                        label: s.name,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (gallery.isNotEmpty) ...<Widget>[
            const FloraSectionHeader(
              title: 'Inspirations',
              padding: EdgeInsets.fromLTRB(20, 8, 12, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: <Widget>[
                  for (final g in gallery)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(FloraTheme.cardRadius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          FloraImage(url: g.imageUrl, label: g.title),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FavoriteButton(
                              favoriteKey: favoriteGalleryKey(g.id),
                              label: g.title ?? 'réalisation',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
