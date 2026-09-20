import 'activity.dart';
import 'coach.dart';

class ScheduleSlot {
  final String id;
  final String activityId;
  final String coachId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isRecurring;
  final DateTime? specificDate;
  final int? maxCapacityOverride;
  final bool isActive;
  final Activity? activity;
  final Coach? coach;

  const ScheduleSlot({
    required this.id,
    required this.activityId,
    required this.coachId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isRecurring = true,
    this.specificDate,
    this.maxCapacityOverride,
    this.isActive = true,
    this.activity,
    this.coach,
  });

  int get capacity => maxCapacityOverride ?? activity?.maxCapacity ?? 0;
  String get activityName => activity?.name ?? '';
  String? get coachName => coach?.name;

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        id: json['id'].toString(),
        activityId: (json['activity_id'] ?? '').toString(),
        coachId: (json['coach_id'] ?? '').toString(),
        dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
        startTime: json['start_time']?.toString() ?? '00:00',
        endTime: json['end_time']?.toString() ?? '00:00',
        isRecurring: json['is_recurring'] as bool? ?? true,
        specificDate: json['specific_date'] != null
            ? DateTime.tryParse(json['specific_date'] as String)
            : null,
        maxCapacityOverride: (json['max_capacity_override'] as num?)?.toInt(),
        isActive: json['is_active'] as bool? ?? true,
        activity: json['activity'] is Map<String, dynamic>
            ? Activity.fromJson(json['activity'] as Map<String, dynamic>)
            : null,
        coach: json['coach'] is Map<String, dynamic>
            ? Coach.fromJson(json['coach'] as Map<String, dynamic>)
            : null,
      );
}
