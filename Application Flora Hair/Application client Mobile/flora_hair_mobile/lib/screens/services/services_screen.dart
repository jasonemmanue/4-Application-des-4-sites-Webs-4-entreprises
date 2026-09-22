import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
// ignore: unused_import  (Category est utilisée dans le type de la liste)
import '../../services/providers.dart';
import '../../widgets/service_card.dart';
import '../../widgets/state_widgets.dart';

final _selectedCategoryProvider = StateProvider<String?>((_) => null);

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final selected = ref.watch(_selectedCategoryProvider);
    final categorySlugToId = <String, String>{
      for (final c in categoriesAsync.valueOrNull ?? const <Category>[])
        c.slug: c.id,
    };
    final selectedCategoryId =
        selected == null ? null : categorySlugToId[selected];

    return Scaffold(
      appBar: AppBar(title: const Text('Nos prestations')),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 52,
            child: categoriesAsync.when(
              data: (cats) => _CategoryFilter(
                categories: cats,
                selected: selected,
                onSelect: (slug) =>
                    ref.read(_selectedCategoryProvider.notifier).state = slug,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, _) => Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    itemBuilder: (context, i) => ServiceCard(
                      service: filtered[i],
                      onTap: () =>
                          context.go('/services/${filtered[i].slug}'),
                    ),
                  ),
                );
              },
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: 'Erreur : $e',
                onRetry: () => ref.refresh(servicesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rangée de pastilles de catégorie style « catalogue » : bordure fine,
/// bordure sombre + fond crème contrasté sur la pastille active. Tout
/// vient du `Theme.of(context)` — pas de couleur en dur, l'écran est
/// lisible dans les deux modes.
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: <Widget>[
        _pill(
          context,
          label: 'Tout',
          active: selected == null,
          onTap: () => onSelect(null),
          scheme: scheme,
        ),
        ...categories.map((c) => _pill(
              context,
              label: c.name,
              active: selected == c.slug,
              onTap: () => onSelect(c.slug),
              scheme: scheme,
            )),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? scheme.onSurface : scheme.surface,
            borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
            border: Border.all(
              color: active ? scheme.onSurface : scheme.outline,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? scheme.surface : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
