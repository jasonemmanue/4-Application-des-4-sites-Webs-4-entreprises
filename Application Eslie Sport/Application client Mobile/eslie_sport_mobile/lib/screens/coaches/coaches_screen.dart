import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../widgets/coach_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class CoachesScreen extends ConsumerWidget {
  const CoachesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coachesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nos coachs')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_2_outlined,
              title: 'Aucun coach',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => CoachCard(coach: list[i]),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(coachesProvider),
        ),
      ),
    );
  }
}
