import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/transformation_slider.dart';

class TransformationsScreen extends ConsumerWidget {
  const TransformationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transformationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Transformations')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.compare_arrows,
              title: 'Aucune transformation',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (_, i) => TransformationSlider(transformation: list[i]),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(transformationsProvider),
        ),
      ),
    );
  }
}
