import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/providers.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/schedule_grid.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _day = DateTime.now().weekday - 1;

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Planning')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(scheduleProvider),
        child: schedule.when(
          data: (list) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: ScheduleGrid(
              slots: list,
              selectedDay: _day,
              onDayChanged: (d) => setState(() => _day = d),
              onSlotTap: (slot) => context.push(
                '/enroll',
                extra: {
                  'activitySlug': null,
                  'slotId': slot.id,
                },
              ),
            ),
          ),
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
