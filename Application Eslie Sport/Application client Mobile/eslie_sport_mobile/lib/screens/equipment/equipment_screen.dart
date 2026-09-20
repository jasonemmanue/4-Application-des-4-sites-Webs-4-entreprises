import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/equipment.dart';
import '../../services/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(equipmentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nos equipements')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.sports_gymnastics,
              title: 'Aucun equipement',
            );
          }
          final byZone = <String, List<Equipment>>{};
          for (final e in list) {
            byZone.putIfAbsent(e.zone, () => []).add(e);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: byZone.entries
                .map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(entry.key.toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6)),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: entry.value.length,
                          itemBuilder: (_, i) {
                            final e = entry.value[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.darkCard,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(AppRadius.md)),
                                      child: e.imageUrl != null &&
                                              e.imageUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: e.imageUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                color: AppColors.darkLighter,
                                                child: const Icon(
                                                    Icons.fitness_center,
                                                    color:
                                                        AppColors.darkMuted),
                                              ),
                                            )
                                          : Container(
                                              color: AppColors.darkLighter,
                                              child: const Icon(
                                                  Icons.fitness_center,
                                                  color: AppColors.darkMuted,
                                                  size: 32),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      e.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ))
                .toList(),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(equipmentProvider),
        ),
      ),
    );
  }
}
