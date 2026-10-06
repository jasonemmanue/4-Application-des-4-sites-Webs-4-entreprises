enum StaffRole { agent, controller }

extension StaffRoleX on StaffRole {
  String get label => this == StaffRole.agent ? 'Agent de nettoyage' : 'Controleur';
  static StaffRole parse(String? v) =>
      (v ?? '').toLowerCase() == 'controller'
          ? StaffRole.controller
          : StaffRole.agent;
}

class StaffUser {
  final int id;
  final String phone;
  final String fullName;
  final StaffRole role;
  final bool active;

  const StaffUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.active,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) => StaffUser(
        id: (json['id'] as num).toInt(),
        phone: json['phone']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        role: StaffRoleX.parse(json['role']?.toString()),
        active: json['active'] != false,
      );

  String get firstName =>
      fullName.split(' ').isNotEmpty ? fullName.split(' ').first : fullName;
}

enum TaskStatus { pending, inProgress, cleaned, controlled, rejected }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'En attente';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.cleaned:
        return 'Nettoye';
      case TaskStatus.controlled:
        return 'Controle';
      case TaskStatus.rejected:
        return 'Rejete';
    }
  }

  String get apiValue {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.cleaned:
        return 'cleaned';
      case TaskStatus.controlled:
        return 'controlled';
      case TaskStatus.rejected:
        return 'rejected';
    }
  }

  static TaskStatus parse(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'in_progress':
      case 'en_cours':
        return TaskStatus.inProgress;
      case 'cleaned':
      case 'nettoye':
        return TaskStatus.cleaned;
      case 'controlled':
      case 'valide':
      case 'controle':
        return TaskStatus.controlled;
      case 'rejected':
      case 'rejete':
        return TaskStatus.rejected;
      default:
        return TaskStatus.pending;
    }
  }
}

class ResidenceSummary {
  final int id;
  final String name;
  final String address;
  final String type;
  final int capacity;

  const ResidenceSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.capacity,
  });

  factory ResidenceSummary.fromJson(Map<String, dynamic> json) =>
      ResidenceSummary(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 2,
      );
}

class TaskPhoto {
  final int id;
  final String url;
  final String phase;
  final DateTime uploadedAt;

  const TaskPhoto({
    required this.id,
    required this.url,
    required this.phase,
    required this.uploadedAt,
  });

  factory TaskPhoto.fromJson(Map<String, dynamic> json) => TaskPhoto(
        id: (json['id'] as num).toInt(),
        url: json['url']?.toString() ?? '',
        phase: json['phase']?.toString() ?? 'after',
        uploadedAt: DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class CleaningTask {
  final int id;
  final ResidenceSummary residence;
  final TaskStatus status;
  final int? assignedToId;
  final String? assignedToName;
  final int? controllerId;
  final String? controllerName;
  final DateTime? nextCheckIn;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? controlledAt;
  final String? rejectionReason;
  final List<TaskPhoto> photos;
  final int estimatedMinutes;

  const CleaningTask({
    required this.id,
    required this.residence,
    required this.status,
    required this.photos,
    required this.estimatedMinutes,
    this.assignedToId,
    this.assignedToName,
    this.controllerId,
    this.controllerName,
    this.nextCheckIn,
    this.startedAt,
    this.completedAt,
    this.controlledAt,
    this.rejectionReason,
  });

  factory CleaningTask.fromJson(Map<String, dynamic> json) => CleaningTask(
        id: (json['id'] as num).toInt(),
        residence: ResidenceSummary.fromJson(
            (json['residence'] as Map).cast<String, dynamic>()),
        status: TaskStatusX.parse(json['status']?.toString()),
        assignedToId: (json['assigned_to_id'] as num?)?.toInt(),
        assignedToName: json['assigned_to_name']?.toString(),
        controllerId: (json['controller_id'] as num?)?.toInt(),
        controllerName: json['controller_name']?.toString(),
        nextCheckIn:
            DateTime.tryParse(json['next_check_in']?.toString() ?? ''),
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
        completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
        controlledAt:
            DateTime.tryParse(json['controlled_at']?.toString() ?? ''),
        rejectionReason: json['rejection_reason']?.toString(),
        estimatedMinutes:
            (json['estimated_minutes'] as num?)?.toInt() ?? 90,
        photos: ((json['photos'] as List?) ?? [])
            .map((e) =>
                TaskPhoto.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Duration? get workingDuration {
    if (startedAt == null) return null;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
}

class StaffStats {
  final int completedCount;
  final int rejectedCount;
  final Duration averageDuration;
  final double validationRate; // 0..1

  const StaffStats({
    required this.completedCount,
    required this.rejectedCount,
    required this.averageDuration,
    required this.validationRate,
  });

  factory StaffStats.fromJson(Map<String, dynamic> json) => StaffStats(
        completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
        rejectedCount: (json['rejected_count'] as num?)?.toInt() ?? 0,
        averageDuration: Duration(
          minutes: (json['average_duration_min'] as num?)?.toInt() ?? 0,
        ),
        validationRate:
            (json['validation_rate'] as num?)?.toDouble() ?? 0,
      );
}
