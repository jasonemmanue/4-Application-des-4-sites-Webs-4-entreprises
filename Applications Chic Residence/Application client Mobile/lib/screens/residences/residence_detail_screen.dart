import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../widgets/state_views.dart';

class ResidenceDetailScreen extends ConsumerWidget {
  const ResidenceDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(residenceDetailProvider(slug));
    return Scaffold(
      body: async.when(
        loading: () => const LoadingCards(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(residenceDetailProvider(slug)),
        ),
        data: (r) => _DetailBody(residence: r),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.residence});
  final Residence residence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.contains(residence.id);
    final compare = ref.watch(compareProvider);
    final inCompare = compare.any((e) => e.id == residence.id);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          leading: const _CircleBackButton(),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.primary500 : Colors.white,
                ),
              ),
              onPressed: () => ref
                  .read(favoritesProvider.notifier)
                  .toggle(residence.id),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'residence-${residence.id}',
              child: PageView.builder(
                itemCount:
                    residence.photos.isEmpty ? 1 : residence.photos.length,
                itemBuilder: (context, i) {
                  final url = residence.photos.isEmpty
                      ? residence.mainPhoto
                      : residence.photos[i];
                  return CachedNetworkImage(
                    imageUrl: ApiConfig.resolveImage(url),
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: context.tokens.imagePlaceholder),
                    errorWidget: (_, __, ___) => Container(
                      color: context.tokens.imagePlaceholder,
                      child: Icon(Icons.image_outlined,
                          size: 40, color: context.tokens.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(residence.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: context.tokens.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${residence.type.label} • ${residence.city}${residence.address.isNotEmpty ? ' — ${residence.address}' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: context.tokens.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.person_outline,
                      text: '${residence.capacity} pers.',
                    ),
                    _InfoPill(
                      icon: Icons.bed_outlined,
                      text: '${residence.bedrooms} chambre(s)',
                    ),
                    _InfoPill(
                      icon: Icons.bathtub_outlined,
                      text: '${residence.bathrooms} sdb',
                    ),
                    if (residence.reviewsCount > 0)
                      _InfoPill(
                        icon: Icons.star_rounded,
                        color: AppColors.sand500,
                        text:
                            '${residence.rating.toStringAsFixed(1)} (${residence.reviewsCount})',
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('A propos',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(residence.description,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Text('Equipements',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final a in residence.amenities)
                      Chip(
                        label: Text(a),
                        avatar: const Icon(Icons.check_circle_outline,
                            size: 18, color: AppColors.primary600),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final ok = ref
                              .read(compareProvider.notifier)
                              .toggle(residence);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                inCompare
                                    ? 'Retire du comparateur'
                                    : ok
                                        ? 'Ajoute au comparateur'
                                        : 'Maximum 3 residences a comparer',
                              ),
                            ),
                          );
                        },
                        icon: Icon(inCompare
                            ? Icons.check_circle
                            : Icons.compare_arrows_rounded),
                        label: Text(inCompare ? 'Compare' : 'Comparer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: residence.availability ==
                                AvailabilityStatus.available
                            ? () => context.push('/book/${residence.slug}')
                            : null,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Reserver'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.tokens.surfaceSunken,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.tokens.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: context.tokens.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A partir de ${Money.fcfa(residence.pricePerNight)} / nuit. '
                          'Depot de 50% requis a la reservation.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withOpacity(0.3),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(
      {required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.tokens.surfaceSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.primary600),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
