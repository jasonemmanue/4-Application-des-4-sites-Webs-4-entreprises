// Modèles alignés sur `StaffOut`, `CleaningTaskOut`, `TaskPhotoOut` et
// `StaffStatsOut` du backend. Les identifiants sont des UUID (texte), et le
// statut final d'une tâche est `validated`.

enum StaffRole { agent, controller, manager }

extension StaffRoleX on StaffRole {
  String get label => switch (this) {
        StaffRole.agent => 'Agent de nettoyage',
        StaffRole.controller => 'Contrôleur',
        StaffRole.manager => 'Gérant',
      };
  static StaffRole parse(String? v) => switch ((v ?? '').toLowerCase()) {
        'controller' => StaffRole.controller,
        'manager' => StaffRole.manager,
        _ => StaffRole.agent,
      };
}

class StaffUser {
  final String id;
  final String phone;
  final String fullName;
  final StaffRole role;
  final bool isActive;

  const StaffUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) => StaffUser(
        id: json['id'].toString(),
        phone: json['phone']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        role: StaffRoleX.parse(json['role']?.toString()),
        isActive: json['is_active'] != false,
      );

  String get firstName => fullName.trim().split(' ').first;
}

enum TaskStatus { pending, inProgress, cleaned, validated, rejected }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'À faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.cleaned:
        return 'À contrôler';
      case TaskStatus.validated:
        return 'Validée';
      case TaskStatus.rejected:
        return 'Rejetée';
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
      case TaskStatus.validated:
        return 'validated';
      case TaskStatus.rejected:
        return 'rejected';
    }
  }

  static TaskStatus parse(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'cleaned':
        return TaskStatus.cleaned;
      case 'validated':
        return TaskStatus.validated;
      case 'rejected':
        return TaskStatus.rejected;
      default:
        return TaskStatus.pending;
    }
  }
}

class ResidenceMini {
  final String id;
  final String title;
  final String city;
  final String address;
  final String type;

  const ResidenceMini({
    required this.id,
    required this.title,
    required this.city,
    required this.address,
    required this.type,
  });

  static const _types = {
    'studio': 'Studio',
    'apartment': 'Appartement',
    'villa': 'Villa',
    'duplex': 'Duplex',
    'room': 'Chambre',
  };

  String get typeLabel => _types[type] ?? type;

  factory ResidenceMini.fromJson(Map<String, dynamic> json) => ResidenceMini(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        type: json['residence_type']?.toString() ?? '',
      );
}

class TaskPhoto {
  final String id;
  final String url;
  final String label; // before | after | rejection
  final DateTime createdAt;

  const TaskPhoto({
    required this.id,
    required this.url,
    required this.label,
    required this.createdAt,
  });

  factory TaskPhoto.fromJson(Map<String, dynamic> json) => TaskPhoto(
        id: json['id'].toString(),
        url: json['url']?.toString() ?? '',
        label: json['label']?.toString() ?? 'after',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class CleaningTask {
  final String id;
  final ResidenceMini? residence;
  final TaskStatus status;
  final String? agentId;
  final String? agentName;
  final String? controllerId;
  final String? controllerName;
  final DateTime? nextCheckIn;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? validatedAt;
  final String rejectionReason;
  final String notes;
  final List<TaskPhoto> photos;

  const CleaningTask({
    required this.id,
    required this.status,
    required this.photos,
    required this.rejectionReason,
    required this.notes,
    this.residence,
    this.agentId,
    this.agentName,
    this.controllerId,
    this.controllerName,
    this.nextCheckIn,
    this.startedAt,
    this.completedAt,
    this.validatedAt,
  });

  String get residenceTitle => residence?.title ?? 'Logement';

  /// Un rejet remet la tâche « à faire » en gardant le motif.
  bool get wasRejected =>
      status == TaskStatus.pending && rejectionReason.isNotEmpty;

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory CleaningTask.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? map(String k) =>
        (json[k] as Map?)?.cast<String, dynamic>();
    return CleaningTask(
      id: json['id'].toString(),
      residence: map('residence') == null
          ? null
          : ResidenceMini.fromJson(map('residence')!),
      status: TaskStatusX.parse(json['status']?.toString()),
      agentId: json['assigned_agent_id']?.toString(),
      agentName: map('assigned_agent')?['full_name']?.toString(),
      controllerId: json['assigned_controller_id']?.toString(),
      controllerName: map('assigned_controller')?['full_name']?.toString(),
      nextCheckIn: _date(json['next_checkin']),
      startedAt: _date(json['started_at']),
      completedAt: _date(json['completed_at']),
      validatedAt: _date(json['validated_at']),
      rejectionReason: json['rejection_reason']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      photos: ((json['photos'] as List?) ?? const [])
          .map((e) => TaskPhoto.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  bool hasPhoto(String label) => photos.any((p) => p.label == label);
}

class StaffStats {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int validatedTasks;
  final int rejectedTasks;
  final double? averageMinutes;
  final double? firstPassRate; // 0..1

  const StaffStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.validatedTasks,
    required this.rejectedTasks,
    this.averageMinutes,
    this.firstPassRate,
  });

  factory StaffStats.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return StaffStats(
      totalTasks: n('total_tasks'),
      completedTasks: n('completed_tasks'),
      inProgressTasks: n('in_progress_tasks'),
      validatedTasks: n('validated_tasks'),
      rejectedTasks: n('rejected_tasks'),
      averageMinutes: (json['average_duration_minutes'] as num?)?.toDouble(),
      firstPassRate: (json['first_pass_rate'] as num?)?.toDouble(),
    );
  }
}
