import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ConsultantDetailScreen extends ConsumerWidget {
  final String id;

  const ConsultantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(teamMemberProvider(id));
    final ws = ref.watch(whatsAppServiceProvider);

    return Scaffold(
      appBar: AppBar(),
      body: member.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(teamMemberProvider(id)),
        ),
        data: (m) {
          if (m == null) {
            return const Center(
              child: Text('Consultant introuvable.'),
            );
          }
          return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.charcoal700,
                  backgroundImage: m.photo != null
                      ? CachedNetworkImageProvider(m.photo!)
                      : null,
                  child: m.photo == null
                      ? const Icon(Icons.person,
                          color: Colors.white70, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(m.name,
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              if (m.role != null)
                Center(
                  child: Text(m.role!,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.brand400)),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (m.specialties.isNotEmpty) ...[
                Text('Specialites',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final s in m.specialties) Chip(label: Text(s))],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (m.bio != null) ...[
                Text('Biographie',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(m.bio!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (m.linkedin != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('LinkedIn'),
                    onPressed: () => ws.openExternalUrl(m.linkedin!),
                  ),
                ),
            ],
          ),
        );
        },
      ),
    );
  }
}
