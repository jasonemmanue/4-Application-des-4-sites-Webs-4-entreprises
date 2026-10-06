// Modeles Backoffice — inclut modeles admin (residence, booking, payment, review)
// et modeles gestionnaires (staff, cleaning task).

class AdminUser {
  final int id;
  final String email;
  final String fullName;
  final String role;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: (json['id'] as num).toInt(),
        email: json['email']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        role: json['role']?.toString() ?? 'admin',
      );
}

class DashboardStats {
  final int residencesCount;
  final int bookingsMonth;
  final double occupancyRate;
  final int revenueMonth;
  final int cleaningInProgress;
  final int cleaningToControl;
  final double firstPassValidationRate;
  final int avgPreparationMinutes;
  final int pendingReviews;
  final int unreadContacts;

  const DashboardStats({
    required this.residencesCount,
    required this.bookingsMonth,
    required this.occupancyRate,
    required this.revenueMonth,
    required this.cleaningInProgress,
    required this.cleaningToControl,
    required this.firstPassValidationRate,
    required this.avgPreparationMinutes,
    required this.pendingReviews,
    required this.unreadContacts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        residencesCount: (json['residences_count'] as num?)?.toInt() ?? 0,
        bookingsMonth: (json['bookings_month'] as num?)?.toInt() ?? 0,
        occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0,
        revenueMonth: (json['revenue_month'] as num?)?.toInt() ?? 0,
        cleaningInProgress:
            (json['cleaning_in_progress'] as num?)?.toInt() ?? 0,
        cleaningToControl:
            (json['cleaning_to_control'] as num?)?.toInt() ?? 0,
        firstPassValidationRate:
            (json['first_pass_validation_rate'] as num?)?.toDouble() ?? 0,
        avgPreparationMinutes:
            (json['avg_preparation_minutes'] as num?)?.toInt() ?? 0,
        pendingReviews: (json['pending_reviews'] as num?)?.toInt() ?? 0,
        unreadContacts: (json['unread_contacts'] as num?)?.toInt() ?? 0,
      );

  factory DashboardStats.empty() => const DashboardStats(
        residencesCount: 0,
        bookingsMonth: 0,
        occupancyRate: 0,
        revenueMonth: 0,
        cleaningInProgress: 0,
        cleaningToControl: 0,
        firstPassValidationRate: 0,
        avgPreparationMinutes: 0,
        pendingReviews: 0,
        unreadContacts: 0,
      );
}

class BookingSummary {
  final int id;
  final String reference;
  final String residenceName;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int totalAmount;
  final String status;

  const BookingSummary({
    required this.id,
    required this.reference,
    required this.residenceName,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    required this.status,
  });

  factory BookingSummary.fromJson(Map<String, dynamic> json) => BookingSummary(
        id: (json['id'] as num).toInt(),
        reference: json['reference']?.toString() ?? '',
        residenceName: json['residence_name']?.toString() ?? '',
        guestName: json['guest_name']?.toString() ?? '',
        checkIn: DateTime.parse(json['check_in'].toString()),
        checkOut: DateTime.parse(json['check_out'].toString()),
        totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'pending',
      );
}

// Modeles de gestion terrain — repris de l'app gestionnaire.
enum StaffRole { agent, controller }

extension StaffRoleX on StaffRole {
  String get label =>
      this == StaffRole.agent ? 'Agent de nettoyage' : 'Controleur';
  static StaffRole parse(String? v) =>
      (v ?? '').toLowerCase() == 'controller'
          ? StaffRole.controller
          : StaffRole.agent;
}

class StaffMember {
  final int id;
  final String phone;
  final String fullName;
  final StaffRole role;
  final bool active;
  final int? completedTasks;

  const StaffMember({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.active,
    this.completedTasks,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: (json['id'] as num).toInt(),
        phone: json['phone']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        role: StaffRoleX.parse(json['role']?.toString()),
        active: json['active'] != false,
        completedTasks: (json['completed_tasks'] as num?)?.toInt(),
      );
}

enum TaskStatus { pending, inProgress, cleaned, controlled, rejected }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'A faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.cleaned:
        return 'A controler';
      case TaskStatus.controlled:
        return 'Termine';
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
        return TaskStatus.controlled;
      case 'rejected':
      case 'rejete':
        return TaskStatus.rejected;
      default:
        return TaskStatus.pending;
    }
  }
}

class TaskSummary {
  final int id;
  final String residenceName;
  final TaskStatus status;
  final String? assignedToName;
  final String? controllerName;
  final DateTime? nextCheckIn;
  final Duration? duration;

  const TaskSummary({
    required this.id,
    required this.residenceName,
    required this.status,
    this.assignedToName,
    this.controllerName,
    this.nextCheckIn,
    this.duration,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) => TaskSummary(
        id: (json['id'] as num).toInt(),
        residenceName: json['residence_name']?.toString() ??
            (json['residence'] is Map
                ? (json['residence'] as Map)['name']?.toString() ?? ''
                : ''),
        status: TaskStatusX.parse(json['status']?.toString()),
        assignedToName: json['assigned_to_name']?.toString(),
        controllerName: json['controller_name']?.toString(),
        nextCheckIn:
            DateTime.tryParse(json['next_check_in']?.toString() ?? ''),
        duration: (json['duration_min'] as num?) != null
            ? Duration(minutes: (json['duration_min'] as num).toInt())
            : null,
      );
}
