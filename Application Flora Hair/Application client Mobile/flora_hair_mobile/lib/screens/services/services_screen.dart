import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/service.dart';
import '../../services/providers.dart';
import '../../widgets/flora_ui.dart';
import '../../widgets/search_bar_pill.dart';
import '../../widgets/state_widgets.dart';
import '../booking/booking_state.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final categorySlugToId = <String, String>{
      for (final c in categoriesAsync.valueOrNull ?? const <Category>[])
        c.slug: c.id,
    };
    final selectedCategoryId =
        selected == null ? null : categorySlugToId[selected];

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 2),
            child: Text(
              'Nos prestations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: FloraColors.textPrimary,
              ),
            ),
          ),
          const SearchBarPill(),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FloraFilterChip(
                    label: 'Tout',
                    active: selected == null,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = null,
                  ),
                ),
                for (final c in categoriesAsync.valueOrNull ??
                    const <Category>[])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FloraFilterChip(
                      label: c.name,
                      active: selected == c.slug,
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = c.slug,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: servicesAsync.when(
              data: (list) {
                final filtered = selectedCategoryId == null
                    ? list
                    : list
                        .where((s) => s.categoryId == selectedCategoryId)
                        .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                      message: 'Aucune prestation dans cette catégorie');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(servicesProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) =>
                        _ServiceRow(service: filtered[i]),
                  ),
                );
              },
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: 'Impossible de charger les services.',
                onRetry: () => ref.refresh(servicesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends ConsumerWidget {
  const _ServiceRow({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloraCard(
      padding: const EdgeInsets.all(10),
      onTap: () => context.push('/services/${service.slug}'),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 112,
              height: 122,
              child: FloraImage(url: service.imageUrl, label: service.name),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: FloraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(Icons.schedule_rounded,
                        size: 15, color: FloraColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      service.formattedDuration,
                      style: const TextStyle(
                          fontSize: 13, color: FloraColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  service.formattedPrice(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FloraColors.burgundy,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    startBookingWith(ref, service);
                    context.go('/booking');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: FloraColors.burgundy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Choisir  →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
