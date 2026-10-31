import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/schedule_slot.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/schedule_grid.dart';

/// Planning sur les 7 prochains jours. La date choisie est transmise a la
/// reservation : c'est elle, pas seulement le creneau, qui compte les places.
class ScheduleScreen extends ConsumerStatefulWidget {
  final String? activityId;
  const ScheduleScreen({super.key, this.activityId});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _date = _today();
  late String? _activityId = widget.activityId;
  bool _dayChosen = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void didUpdateWidget(ScheduleScreen old) {
    super.didUpdateWidget(old);
    if (widget.activityId != old.activityId) {
      _activityId = widget.activityId;
      _dayChosen = false;
    }
  }

  /// Venant d'une fiche activite, on se place sur son prochain jour de cours.
  DateTime _effectiveDate(List<ScheduleSlot> slots) {
    if (_dayChosen || _activityId == null) return _date;
    for (var i = 0; i < 7; i++) {
      final day = _today().add(Duration(days: i));
      if (slots.any((s) => s.dayOfWeek == day.weekday - 1)) return day;
    }
    return _date;
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final settings = ref.watch(publicSettingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Planning')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(scheduleProvider);
          ref.invalidate(slotAvailabilityProvider);
          ref.invalidate(publicSettingsProvider);
        },
        child: schedule.when(
          data: (all) {
            final slots = _activityId == null
                ? all
                : all.where((s) => s.activityId == _activityId).toList();
            final activityName = _activityId != null && slots.isNotEmpty
                ? slots.first.activityName
                : null;
            final date = _effectiveDate(slots);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _DayStrip(
                  start: _today(),
                  selected: date,
                  onSelect: (d) => setState(() {
                    _date = d;
                    _dayChosen = true;
                  }),
                ),
                if (activityName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text(activityName),
                        onDeleted: () => setState(() {
                          _activityId = null;
                          _date = date;
                          _dayChosen = true;
                        }),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                ScheduleDayList(
                  slots: slots,
                  date: date,
                  onBook: (slot) => context.push(
                    '/enroll',
                    extra: {'slotId': slot.id, 'date': date},
                  ),
                ),
                const SizedBox(height: 14),
                const _DepositCard(),
                if (settings?.openingHours != null) ...[
                  const SizedBox(height: 12),
                  _HoursCard(hours: settings!.openingHours!),
                ],
              ],
            );
          },
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(scheduleProvider),
          ),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  final DateTime start;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _DayStrip({
    required this.start,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _DayCell(
                day: start.add(Duration(days: i)),
                active: start.add(Duration(days: i)) == selected,
                onTap: () => onSelect(start.add(Duration(days: i))),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool active;
  final VoidCallback onTap;
  const _DayCell({required this.day, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.onPrimary : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        selected: active,
        label: formatDate(day),
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    weekDayName(day.weekday - 1, short: true),
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepositCard extends StatelessWidget {
  const _DepositCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.percent_rounded,
                color: AppColors.onPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acompte : 50 %',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Réglez 50 % pour réserver votre place, le reste à la salle.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  final String hours;
  const _HoursCard({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horaires de la salle',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hours,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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
