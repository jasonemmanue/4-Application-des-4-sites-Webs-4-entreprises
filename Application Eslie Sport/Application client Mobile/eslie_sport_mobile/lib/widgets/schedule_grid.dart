import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/schedule_slot.dart';
import '../utils/formatters.dart';

class ScheduleGrid extends StatelessWidget {
  final List<ScheduleSlot> slots;
  final void Function(ScheduleSlot slot) onSlotTap;
  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  const ScheduleGrid({
    super.key,
    required this.slots,
    required this.onSlotTap,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final daySlots = slots.where((s) => s.dayOfWeek == selectedDay).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = i == selectedDay;
              return GestureDetector(
                onTap: () => onDayChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: active ? AppColors.goldGradient : null,
                    color: active ? null : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: active ? Colors.transparent : AppColors.darkBorder,
                    ),
                  ),
                  child: Text(
                    weekDayName(i, short: true),
                    style: TextStyle(
                      color: active ? AppColors.dark : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (daySlots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Aucun cours prevu ce jour.',
                style: TextStyle(color: AppColors.darkMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: daySlots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _SlotTile(
              slot: daySlots[i],
              onTap: () => onSlotTap(daySlots[i]),
            ),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  final ScheduleSlot slot;
  final VoidCallback onTap;
  const _SlotTile({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.activityName.isNotEmpty
                          ? slot.activityName
                          : 'Cours',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (slot.coachName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Coach ${slot.coachName!}',
                        style: const TextStyle(
                          color: AppColors.darkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (slot.capacity > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Capacite : ${slot.capacity}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.darkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
