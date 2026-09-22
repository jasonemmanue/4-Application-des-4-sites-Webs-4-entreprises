import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/team_card.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notre equipe')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(message: 'Aucune coiffeuse a afficher');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, i) => TeamCard(member: list[i]),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Erreur : $e',
          onRetry: () => ref.refresh(teamProvider),
        ),
      ),
    );
  }
}
