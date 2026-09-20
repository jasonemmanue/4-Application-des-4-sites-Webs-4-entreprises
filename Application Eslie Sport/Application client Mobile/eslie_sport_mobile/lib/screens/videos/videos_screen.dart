import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class VideosScreen extends ConsumerWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Videos')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.play_circle_outline,
              title: 'Aucune video',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final v = list[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse(v.videoUrl),
                      mode: LaunchMode.externalApplication),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.md)),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: v.thumbnailUrl != null &&
                                        v.thumbnailUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: v.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                            color: AppColors.darkLighter),
                                      )
                                    : Container(color: AppColors.darkLighter),
                              ),
                            ),
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_fill,
                                    color: AppColors.primary, size: 56),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(v.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(videosProvider),
        ),
      ),
    );
  }
}
