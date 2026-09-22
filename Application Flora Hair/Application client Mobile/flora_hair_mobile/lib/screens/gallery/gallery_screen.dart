import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../widgets/gallery_grid.dart';
import '../../widgets/state_widgets.dart';

final _tagFilterProvider = StateProvider<String?>((_) => null);

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(galleryProvider);
    final tag = ref.watch(_tagFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Galerie')),
      body: async.when(
        data: (list) {
          final tags = <String>{
            for (final it in list) ...it.tags,
          }.toList()
            ..sort();
          final filtered = tag == null
              ? list
              : list.where((it) => it.tags.contains(tag)).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(galleryProvider.future),
            child: ListView(
              children: <Widget>[
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: ChoiceChip(
                          label: const Text('Tout'),
                          selected: tag == null,
                          selectedColor: FloraColors.lime,
                          onSelected: (_) =>
                              ref.read(_tagFilterProvider.notifier).state = null,
                        ),
                      ),
                      ...tags.map(
                        (t) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: ChoiceChip(
                            label: Text(t),
                            selected: tag == t,
                            selectedColor: FloraColors.lime,
                            onSelected: (_) =>
                                ref.read(_tagFilterProvider.notifier).state = t,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(message: 'Aucune photo pour ce filtre'),
                  )
                else
                  GalleryGrid(items: filtered),
              ],
            ),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Erreur : $e',
          onRetry: () => ref.refresh(galleryProvider),
        ),
      ),
    );
  }
}
