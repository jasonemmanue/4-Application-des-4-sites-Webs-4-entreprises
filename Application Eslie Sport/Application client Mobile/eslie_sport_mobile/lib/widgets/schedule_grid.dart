import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/schedule_slot.dart';
import '../services/providers.dart';
import 'activity_card.dart';

/// Les cours d'une date : photo, nom, duree, places restantes, reservation.
class ScheduleDayList extends StatelessWidget {
  final List<ScheduleSlot> slots;
  final DateTime date;
  final ValueChanged<ScheduleSlot> onBook;

  const ScheduleDayList({
    super.key,
    required this.slots,
    required this.date,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final daySlots = slots
        .where((s) => s.isActive && s.dayOfWeek == date.weekday - 1)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (daySlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Aucun cours prévu ce jour.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final slot in daySlots)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SlotCard(slot: slot, date: date, onBook: () => onBook(slot)),
          ),
      ],
    );
  }
}

class SlotCard extends StatelessWidget {
  final ScheduleSlot slot;
  final DateTime date;
  final VoidCallback onBook;
  const SlotCard({
    super.key,
    required this.slot,
    required this.date,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final activity = slot.activity;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ActivityPhoto(
                  url: activity?.imageUrl,
                  category: activity?.category ?? '',
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${slot.startTime} – ${slot.endTime}',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.activityName.isNotEmpty ? slot.activityName : 'Cours',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (activity != null)
                      _Meta(Icons.schedule, '${activity.durationMinutes} min'),
                    _PlacesLeft(slotId: slot.id, date: date),
                    if (slot.coachName != null)
                      _Meta(Icons.person_outline, 'Coach ${slot.coachName!}'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onBook,
                    icon: const Icon(Icons.event_available, size: 20),
                    label: const Text('Réserver ma place'),
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

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Meta(this.icon, this.text, {this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Places restantes en temps reel. Vert, orange sous 5 places, rouge a zero.
class _PlacesLeft extends ConsumerWidget {
  final String slotId;
  final DateTime date;
  const _PlacesLeft({required this.slotId, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places =
        ref.watch(slotAvailabilityProvider((slotId: slotId, date: date)));
    final count = places.valueOrNull;
    if (count == null) return const SizedBox.shrink();
    if (count == 0) {
      return const _Meta(Icons.group_off_outlined, 'Complet — liste d\'attente',
          color: AppColors.error);
    }
    return _Meta(
      Icons.groups_outlined,
      '$count ${count > 1 ? 'places restantes' : 'place restante'}',
      color: count < 5 ? AppColors.warning : AppColors.success,
    );
  }
}
