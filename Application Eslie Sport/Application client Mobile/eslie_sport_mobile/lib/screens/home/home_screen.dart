/// Accueil : logo en haut a gauche, hero « Reserver une seance », acces
/// rapides, prochain cours et tarifs lus en direct depuis l'API, coachs et
/// transformations, pastille « acompte 50 % ».
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/coach.dart';
import '../../models/schedule_slot.dart';
import '../../models/subscription.dart';
import '../../models/transformation.dart';
import '../../services/member_profile.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/deposit_notice.dart';
import '../../widgets/section_title.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final subscriptions = ref.watch(subscriptionsProvider);
    final coaches = ref.watch(coachesProvider);
    final transformations = ref.watch(featuredTransformationsProvider);

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(scheduleProvider);
              ref.invalidate(subscriptionsProvider);
              ref.invalidate(coachesProvider);
              ref.invalidate(featuredTransformationsProvider);
              ref.invalidate(slotAvailabilityProvider);
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _Header(),
                const _Hero(),
                const SizedBox(height: 16),
                const _QuickLinks(),
                const SizedBox(height: 16),
                ...schedule.maybeWhen(
                  data: (slots) {
                    final next = _nextClass(slots);
                    return next == null
                        ? const <Widget>[]
                        : [_NextClassCard(slot: next.$1, date: next.$2)];
                  },
                  orElse: () => const <Widget>[],
                ),
                ...subscriptions.maybeWhen(
                  data: (list) =>
                      list.isEmpty ? const <Widget>[] : [_PricesCard(list: list)],
                  orElse: () => const <Widget>[],
                ),
                ...coaches.maybeWhen(
                  data: (list) => list.isEmpty
                      ? const <Widget>[]
                      : [
                          SectionTitle(
                            title: 'Vos coachs',
                            onAction: () => context.push('/coaches'),
                          ),
                          SizedBox(
                            height: 136,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) =>
                                  _CoachTile(coach: list[i]),
                            ),
                          ),
                        ],
                  orElse: () => const <Widget>[],
                ),
                ...transformations.maybeWhen(
                  data: (list) => list.isEmpty
                      ? const <Widget>[]
                      : [
                          SectionTitle(
                            title: 'Ils ont transformé leur corps',
                            onAction: () => context.push('/transformations'),
                          ),
                          SizedBox(
                            height: 148,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) =>
                                  _TransformationTile(item: list[i]),
                            ),
                          ),
                        ],
                  orElse: () => const <Widget>[],
                ),
                const SizedBox(height: 96),
              ],
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Center(child: DepositNoticePill()),
          ),
        ],
      ),
    );
  }

  /// Prochain cours a partir de maintenant, sur les 7 jours a venir.
  static (ScheduleSlot, DateTime)? _nextClass(List<ScheduleSlot> slots) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final clock = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    for (var offset = 0; offset < 7; offset++) {
      final date = today.add(Duration(days: offset));
      final candidates = slots
          .where((s) =>
              s.isActive &&
              s.dayOfWeek == date.weekday - 1 &&
              (offset > 0 || s.startTime.compareTo(clock) > 0))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (candidates.isNotEmpty) return (candidates.first, date);
    }
    return null;
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(memberNameProvider);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            const BrandLogo(),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Mon profil',
              excludeSemantics: true,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.go('/more'),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.primarySoft,
                  child: name == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : Text(
                          name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          height: 268,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/hero-accueil.jpg',
                fit: BoxFit.cover,
                semanticLabel: 'Séance de musculation en salle',
              ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.heroOverlay),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ton énergie.\nTes objectifs.',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Text(
                      'Notre équipe.',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: AppShadows.cta,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/schedule'),
                        icon: const Icon(Icons.event_available, size: 20),
                        label: const Text('Réserver une séance'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _QuickLink(
            icon: Icons.directions_run,
            label: 'Activités',
            onTap: () => context.go('/activities'),
          ),
          const SizedBox(width: 10),
          _QuickLink(
            icon: Icons.calendar_month,
            label: 'Planning',
            onTap: () => context.go('/schedule'),
          ),
          const SizedBox(width: 10),
          _QuickLink(
            icon: Icons.workspace_premium,
            label: 'Abonnements',
            onTap: () => context.go('/subscriptions'),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                children: [
                  Icon(icon, color: AppColors.primary, size: 32),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextClassCard extends ConsumerWidget {
  final ScheduleSlot slot;
  final DateTime date;
  const _NextClassCard({required this.slot, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref
        .watch(slotAvailabilityProvider((slotId: slot.id, date: date)))
        .valueOrNull;
    final today = DateTime.now();
    final isToday = date.day == today.day && date.month == today.month;
    final activity = slot.activity;

    return _HomeCard(
      onTap: () => context.push(
        '/enroll',
        extra: {'slotId': slot.id, 'date': date},
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ActivityPhoto(
              url: activity?.imageUrl,
              category: activity?.category ?? '',
              width: 112,
              height: 96,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prochain cours',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slot.activityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${isToday ? "Aujourd'hui" : weekDayName(date.weekday - 1)}'
                        ' · ${slot.startTime} – ${slot.endTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (places != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      places == 0
                          ? 'Complet'
                          : '$places ${places > 1 ? 'places restantes' : 'place restante'}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricesCard extends StatelessWidget {
  final List<Subscription> list;
  const _PricesCard({required this.list});

  @override
  Widget build(BuildContext context) {
    final main = list
        .where((s) => !s.name.contains('—'))
        .take(3)
        .toList(growable: false);
    return _HomeCard(
      onTap: () => context.go('/subscriptions'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nos tarifs',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final s in main)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${s.name} : ${formatFcfa(s.price)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const RoundArrow(
            background: AppColors.yellow,
            foreground: AppColors.textPrimary,
            size: 38,
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HomeCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ),
      ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  final Coach coach;
  const _CoachTile({required this.coach});

  @override
  Widget build(BuildContext context) {
    final photo = coach.photoUrl;
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primarySoft,
            backgroundImage: photo != null && photo.isNotEmpty
                ? CachedNetworkImageProvider(photo)
                : null,
            child: photo == null || photo.isEmpty
                ? Text(
                    coach.name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            coach.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (coach.specialties.isNotEmpty)
            Text(
              coach.specialties.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _TransformationTile extends StatelessWidget {
  final Transformation item;
  const _TransformationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.memberName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((item.durationText ?? '').isNotEmpty)
            Text(
              item.durationText!,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              item.testimonial ?? '',
              overflow: TextOverflow.fade,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
