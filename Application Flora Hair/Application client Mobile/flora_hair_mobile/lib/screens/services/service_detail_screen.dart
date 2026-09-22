import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/providers.dart';
import '../../utils/media.dart';
import '../../widgets/state_widgets.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serviceDetailProvider(slug));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail')),
      body: async.when(
        data: (service) => ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            if (service.imageUrl != null && service.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: mediaUrl(service.imageUrl),
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: scheme.surfaceContainerHighest),
                  placeholder: (_, __) =>
                      Container(color: scheme.surfaceContainerHighest),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(service.name, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Icon(Icons.access_time, size: 18, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text('${service.durationMinutes} min',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 20),
                      Text(
                        service.formattedPrice(),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    service.description ??
                        'Un moment de beauté cousu main pour sublimer votre style.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/booking'),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Réserver cette prestation'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Impossible de charger le service : $e',
          onRetry: () => ref.refresh(serviceDetailProvider(slug)),
        ),
      ),
    );
  }
}
