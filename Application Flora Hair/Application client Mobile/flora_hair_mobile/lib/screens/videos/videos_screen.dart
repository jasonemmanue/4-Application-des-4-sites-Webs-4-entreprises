import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../utils/media.dart';
import '../../widgets/state_widgets.dart';

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
            return const EmptyState(message: 'Aucune video pour le moment');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final v = list[i];
              return InkWell(
                borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
                onTap: () => launchUrl(
                  Uri.parse(v.url),
                  mode: LaunchMode.externalApplication,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: FloraColors.charcoal,
                    border: Border.all(color: FloraColors.grayWarm),
                    borderRadius:
                        BorderRadius.circular(FloraTheme.cardRadius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            if (v.thumbnailUrl != null)
                              CachedNetworkImage(
                                imageUrl: mediaUrl(v.thumbnailUrl),
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    Container(color: FloraColors.darkLight),
                              )
                            else
                              Container(color: FloraColors.darkLight),
                            Container(color: Colors.black.withValues(alpha: 0.35)),
                            const Center(
                              child: Icon(Icons.play_circle_fill,
                                  size: 64, color: FloraColors.lime),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(v.title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Erreur : $e',
          onRetry: () => ref.refresh(videosProvider),
        ),
      ),
    );
  }
}
