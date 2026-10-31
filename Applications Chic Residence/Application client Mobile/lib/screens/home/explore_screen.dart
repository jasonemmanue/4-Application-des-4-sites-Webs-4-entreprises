import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/residence.dart';
import '../../providers/providers.dart';
import '../../services/residence_service.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';

/// Onglet Explorer : barre de recherche, pastilles de type, filtres, résultats.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final _controller =
      TextEditingController(text: ref.read(filtersProvider).query ?? '');
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref
          .read(filtersProvider.notifier)
          .update((s) => s.copyWith(query: q.trim(), page: 1));
    });
  }

  Future<void> _openFilters() async {
    final current = ref.read(filtersProvider);
    final result = await showModalBottomSheet<ResidenceFilters>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _FiltersSheet(initial: current),
    );
    if (result != null) ref.read(filtersProvider.notifier).state = result;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final filters = ref.watch(filtersProvider);
    final draft = ref.watch(stayDraftProvider);
    final async = ref.watch(residencesProvider);

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: t.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: t.shadow,
                            blurRadius: 12,
                            spreadRadius: -4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        onChanged: _onChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un logement...',
                          prefixIcon: Icon(Icons.search_rounded,
                              color: t.textSecondary),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _controller.clear();
                                    _onChanged('');
                                  },
                                ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: t.surfaceElevated,
                    shape: const CircleBorder(),
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _openFilters,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Semantics(
                          label: 'Filtres',
                          button: true,
                          child: Icon(Icons.tune_rounded, color: t.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  _TypeChip(
                    label: 'Tous',
                    selected: filters.type == null,
                    onTap: () => ref
                        .read(filtersProvider.notifier)
                        .update((s) => s.copyWith(clearType: true)),
                  ),
                  for (final type in ResidenceType.values)
                    _TypeChip(
                      label: type.label,
                      selected: filters.type == type,
                      onTap: () => ref
                          .read(filtersProvider.notifier)
                          .update((s) => s.copyWith(type: type)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: async.when(
                loading: () => const LoadingCards(count: 3),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(residencesProvider),
                ),
                data: (raw) {
                  final list = draft.hasDates
                      ? raw
                          .where((r) =>
                              r.isFreeBetween(draft.checkIn!, draft.checkOut!))
                          .toList()
                      : raw;
                  if (list.isEmpty) {
                    return const EmptyView(
                      title: 'Rien trouvé',
                      description:
                          'Modifiez votre recherche, vos dates ou vos filtres.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(residencesProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => ResidenceCard(
                        residence: list[i],
                        imageHeight: 170,
                        onTap: () => context.push('/residence/${list[i].slug}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? t.chipBgSelected : t.chipBg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? t.chipBgSelected : t.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : t.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});
  final ResidenceFilters initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late int _capacity = widget.initial.capacity ?? 1;
  late String _sort = widget.initial.sort ?? 'order';

  static const _sorts = {
    'order': 'Recommandé',
    'price_asc': 'Prix croissant',
    'price_desc': 'Prix décroissant',
    'newest': 'Plus récent',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtres', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Capacité minimale',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.outlined(
                  onPressed:
                      _capacity > 1 ? () => setState(() => _capacity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 110,
                  child: Text('$_capacity pers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton.outlined(
                  onPressed:
                      _capacity < 20 ? () => setState(() => _capacity++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Trier par', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _sorts.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _sort == e.key,
                    onSelected: (_) => setState(() => _sort = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                widget.initial.copyWith(
                  capacity: _capacity > 1 ? _capacity : null,
                  clearCapacity: _capacity <= 1,
                  sort: _sort,
                ),
              ),
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}
