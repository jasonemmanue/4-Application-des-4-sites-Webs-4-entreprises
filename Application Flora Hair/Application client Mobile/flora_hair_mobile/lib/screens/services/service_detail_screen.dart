import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/service.dart';
import '../../services/favorites.dart';
import '../../services/providers.dart';
import '../../widgets/flora_ui.dart';
import '../../widgets/state_widgets.dart';
import '../booking/booking_state.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serviceDetailProvider(slug));
    return Scaffold(
      body: async.when(
        data: (service) => _Detail(service: service),
        loading: () => const LoadingState(),
        error: (e, _) => SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: BackButton(onPressed: () => context.pop()),
              ),
              Expanded(
                child: ErrorState(
                  message: 'Impossible de charger le service.',
                  onRetry: () => ref.refresh(serviceDetailProvider(slug)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (service) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: ElevatedButton(
              onPressed: () {
                startBookingWith(ref, service);
                context.go('/booking');
              },
              child: const Text('Prendre rendez-vous'),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(salonRatingProvider);
    final team = ref.watch(teamProvider).valueOrNull ?? const [];
    final similar = (ref.watch(servicesProvider).valueOrNull ?? const <Service>[])
        .where((s) => s.categoryId == service.categoryId && s.id != service.id)
        .take(6)
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        SizedBox(
          height: 340,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FloraImage(url: service.imageUrl, label: service.name),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 10,
                left: 16,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: 'Retour',
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: FloraColors.textPrimary),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/services'),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 10,
                right: 16,
                child: FavoriteButton(
                  favoriteKey: favoriteServiceKey(service.slug),
                  label: service.name,
                  size: 48,
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Container(
            decoration: const BoxDecoration(
              color: FloraColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                    color: FloraColors.textPrimary,
                  ),
                ),
                // Note réelle du salon, calculée sur les avis approuvés dans
                // l'administration. L'API ne note pas chaque prestation.
                if (rating != null) ...<Widget>[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => context.push('/reviews'),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.star_rounded,
                            color: FloraColors.gold, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          rating.average
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: FloraColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${rating.count} avis sur le salon',
                          style: const TextStyle(
                            fontSize: 13,
                            color: FloraColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if ((service.description ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    service.description!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: FloraColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.schedule_rounded,
                        label: 'Durée estimée',
                        value: service.formattedDuration,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.sell_outlined,
                        label: service.priceType == ServicePriceType.fixed
                            ? 'Tarif'
                            : 'À partir de',
                        value: formatFcfa(service.priceMin),
                      ),
                    ),
                  ],
                ),
                if (team.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  FloraCard(
                    onTap: () => context.push('/team'),
                    child: Row(
                      children: <Widget>[
                        ClipOval(
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: FloraImage(
                              url: team.first.photoUrl,
                              label: team.first.name,
                              icon: Icons.person_outline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Nos expert·es',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: FloraColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Vous choisissez à la réservation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: FloraColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: FloraColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (similar.isNotEmpty) ...<Widget>[
          const FloraSectionHeader(
            title: 'Styles similaires',
            padding: EdgeInsets.fromLTRB(20, 0, 12, 10),
          ),
          SizedBox(
            height: 132,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              scrollDirection: Axis.horizontal,
              itemCount: similar.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/services/${similar[i].slug}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 112,
                    child: FloraImage(
                      url: similar[i].imageUrl,
                      label: similar[i].name,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FloraCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, color: FloraColors.burgundy, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: FloraColors.textSecondary),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FloraColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
