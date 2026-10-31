// Modèles alignés sur les schémas du backend (`schemas.py`). Les identifiants
// sont des UUID (texte) et les montants des `Decimal` sérialisés en texte
// (« 25000.00 ») : l'ancien `(json['id'] as num)` plantait à la lecture, juste
// après une connexion réussie.

int asInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().split('.').first) ?? 0;
}

DateTime? asDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

class AdminUser {
  final String id;
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
        id: json['id'].toString(),
        email: json['email']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
      );
}

class Paged<T> {
  final List<T> items;
  final int total;
  const Paged(this.items, this.total);
}

class DashboardStats {
  final int totalResidences;
  final int activeResidences;
  final int totalBookings;
  final int pendingBookings;
  final int totalRevenue;
  final double occupancyRate; // déjà en %
  final int soldNights;
  final int offeredNights;
  final int unreadContacts;
  final int pendingReviews;
  final List<Booking> upcoming;

  const DashboardStats({
    required this.totalResidences,
    required this.activeResidences,
    required this.totalBookings,
    required this.pendingBookings,
    required this.totalRevenue,
    required this.occupancyRate,
    required this.soldNights,
    required this.offeredNights,
    required this.unreadContacts,
    required this.pendingReviews,
    required this.upcoming,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalResidences: asInt(json['total_residences']),
        activeResidences: asInt(json['active_residences']),
        totalBookings: asInt(json['total_bookings']),
        pendingBookings: asInt(json['pending_bookings']),
        totalRevenue: asInt(json['total_revenue']),
        occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0,
        soldNights: asInt(json['occupancy_sold_nights']),
        offeredNights: asInt(json['occupancy_offered_nights']),
        unreadContacts: asInt(json['unread_contacts']),
        pendingReviews: asInt(json['pending_reviews']),
        upcoming: ((json['upcoming_bookings'] as List?) ?? const [])
            .map((e) => Booking.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class Booking {
  final String id;
  final String residenceId;
  final String guestName;
  final String guestPhone;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int total;
  final int deposit;
  final String depositStatus;
  final String status;
  final String notes;
  final DateTime? createdAt;

  const Booking({
    required this.id,
    required this.residenceId,
    required this.guestName,
    required this.guestPhone,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.total,
    required this.deposit,
    required this.depositStatus,
    required this.status,
    required this.notes,
    this.createdAt,
  });

  bool get depositPaid => depositStatus == 'paid';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'].toString(),
        residenceId: json['residence_id'].toString(),
        guestName: json['guest_name']?.toString() ?? '',
        guestPhone: json['guest_phone']?.toString() ?? '',
        checkIn: DateTime.parse(json['check_in'].toString()),
        checkOut: DateTime.parse(json['check_out'].toString()),
        guests: asInt(json['num_guests']),
        total: asInt(json['total_price']),
        deposit: asInt(json['deposit_amount']),
        depositStatus: json['deposit_status']?.toString() ?? 'unpaid',
        status: json['status']?.toString() ?? 'pending',
        notes: json['notes']?.toString() ?? '',
        createdAt: asDate(json['created_at']),
      );
}

class Payment {
  final String id;
  final String reference;
  final String bookingId;
  final String channelLabel;
  final String mode;
  final int amount;
  final int bookingTotal;
  final String status;
  final String customerPhone;
  final String failureReason;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    required this.reference,
    required this.bookingId,
    required this.channelLabel,
    required this.mode,
    required this.amount,
    required this.bookingTotal,
    required this.status,
    required this.customerPhone,
    required this.failureReason,
    this.paidAt,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'].toString(),
        reference: json['reference']?.toString() ?? '',
        bookingId: json['booking_id'].toString(),
        channelLabel: (json['channel_label'] ?? json['channel'] ?? '').toString(),
        mode: json['mode']?.toString() ?? '',
        amount: asInt(json['amount']),
        bookingTotal: asInt(json['booking_total']),
        status: json['status']?.toString() ?? 'pending',
        customerPhone: json['customer_phone']?.toString() ?? '',
        failureReason: json['failure_reason']?.toString() ?? '',
        paidAt: asDate(json['paid_at']),
        createdAt: asDate(json['created_at']),
      );
}

class Review {
  final String id;
  final String? residenceId;
  final String author;
  final int rating;
  final String comment;
  final bool approved;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    required this.approved,
    this.residenceId,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'].toString(),
        residenceId: json['residence_id']?.toString(),
        author: json['author_name']?.toString() ?? '',
        rating: asInt(json['rating']),
        comment: json['comment']?.toString() ?? '',
        approved: json['is_approved'] == true,
        createdAt: asDate(json['created_at']),
      );
}

class ContactMessage {
  final String id;
  final String name;
  final String phone;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const ContactMessage({
    required this.id,
    required this.name,
    required this.phone,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) => ContactMessage(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        isRead: json['is_read'] == true,
        createdAt: asDate(json['created_at']),
      );
}

class SettingItem {
  final String key;
  final String value;
  const SettingItem(this.key, this.value);

  factory SettingItem.fromJson(Map<String, dynamic> json) =>
      SettingItem(json['key'].toString(), json['value']?.toString() ?? '');
}

const residenceTypes = {
  'studio': 'Studio',
  'apartment': 'Appartement',
  'villa': 'Villa',
  'duplex': 'Duplex',
  'room': 'Chambre',
};

/// Mêmes clés et libellés que `AMENITIES` de l'admin web : les valeurs stockées
/// en base sont ces clés, le site et l'application cliente les traduisent.
const amenityLabels = {
  'ac': 'Climatisation',
  'wifi': 'Wi-Fi',
  'tv': 'TV / Netflix / Canal+',
  'kitchen': 'Cuisine équipée',
  'washer': 'Machine à laver',
  'iron': 'Fer à repasser',
  'hot_water': 'Eau chaude',
  'parking': 'Parking / garage',
  'outdoor_space': 'Jardin / terrasse / balcon',
  'security': 'Sécurité',
  'linens': 'Linge de maison fourni',
  'toiletries': "Produits d'accueil",
  'pool': 'Piscine',
  'generator': 'Groupe électrogène',
  'elevator': 'Ascenseur',
  'furnished': 'Entièrement meublé',
};

class Residence {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? unitNumber;
  final String address;
  final String city;
  final String type;
  final int capacity;
  final int bedrooms;
  final int bathrooms;
  final int? areaSqm;
  final int price;
  final List<String> amenities;
  final List<String> images;
  final bool isActive;
  final bool isFeatured;
  final String availabilityStatus; // auto | occupied | maintenance
  final String availabilityLabel;
  final String availabilityState; // free | busy | maintenance

  const Residence({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.address,
    required this.city,
    required this.type,
    required this.capacity,
    required this.bedrooms,
    required this.bathrooms,
    required this.price,
    required this.amenities,
    required this.images,
    required this.isActive,
    required this.isFeatured,
    required this.availabilityStatus,
    required this.availabilityLabel,
    required this.availabilityState,
    this.unitNumber,
    this.areaSqm,
  });

  String get typeLabel => residenceTypes[type] ?? type;
  String? get photo => images.isEmpty ? null : images.first;

  factory Residence.fromJson(Map<String, dynamic> json) {
    final summary =
        (json['availability_summary'] as Map?)?.cast<String, dynamic>();
    return Residence(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      unitNumber: json['unit_number']?.toString(),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      type: json['residence_type']?.toString() ?? 'apartment',
      capacity: asInt(json['capacity']),
      bedrooms: asInt(json['bedrooms']),
      bathrooms: asInt(json['bathrooms']),
      areaSqm: json['area_sqm'] == null ? null : asInt(json['area_sqm']),
      price: asInt(json['base_price_per_night']),
      amenities: ((json['amenities'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      images: ((json['images'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      isActive: json['is_active'] != false,
      isFeatured: json['is_featured'] == true,
      availabilityStatus: json['availability_status']?.toString() ?? 'auto',
      availabilityLabel: summary?['label']?.toString() ?? 'Libre',
      availabilityState: summary?['state']?.toString() ?? 'free',
    );
  }
}

// ── Suivi terrain ─────────────────────────────────────────────────────────

enum StaffRole { agent, controller }

extension StaffRoleX on StaffRole {
  String get label =>
      this == StaffRole.agent ? 'Agent de nettoyage' : 'Contrôleur';
  static StaffRole parse(String? v) =>
      (v ?? '').toLowerCase() == 'controller'
          ? StaffRole.controller
          : StaffRole.agent;
}

class StaffMember {
  final String id;
  final String phone;
  final String fullName;
  final StaffRole role;
  final bool isActive;
  final DateTime? lastLoginAt;

  const StaffMember({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'].toString(),
        phone: json['phone']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        role: StaffRoleX.parse(json['role']?.toString()),
        isActive: json['is_active'] != false,
        lastLoginAt: asDate(json['last_login_at']),
      );
}

class StaffStats {
  final int completed;
  final int validated;
  final int rejected;
  final double? averageMinutes;
  final double? firstPassRate; // 0..1

  const StaffStats({
    required this.completed,
    required this.validated,
    required this.rejected,
    this.averageMinutes,
    this.firstPassRate,
  });

  factory StaffStats.fromJson(Map<String, dynamic> json) => StaffStats(
        completed: asInt(json['completed_tasks']),
        validated: asInt(json['validated_tasks']),
        rejected: asInt(json['rejected_tasks']),
        averageMinutes: (json['average_duration_minutes'] as num?)?.toDouble(),
        firstPassRate: (json['first_pass_rate'] as num?)?.toDouble(),
      );
}

class CleaningOverview {
  final int pending;
  final int inProgress;
  final int cleaned;
  final int validated;
  final int rejected;
  final int total;

  const CleaningOverview({
    required this.pending,
    required this.inProgress,
    required this.cleaned,
    required this.validated,
    required this.rejected,
    required this.total,
  });

  factory CleaningOverview.fromJson(Map<String, dynamic> json) =>
      CleaningOverview(
        pending: asInt(json['pending']),
        inProgress: asInt(json['in_progress']),
        cleaned: asInt(json['cleaned']),
        validated: asInt(json['validated']),
        rejected: asInt(json['rejected']),
        total: asInt(json['total']),
      );
}

class PerformancePoint {
  final DateTime date;
  final int completed;
  final int validated;
  final int rejected;

  const PerformancePoint(
      this.date, this.completed, this.validated, this.rejected);

  factory PerformancePoint.fromJson(Map<String, dynamic> json) =>
      PerformancePoint(
        DateTime.parse(json['date'].toString()),
        asInt(json['tasks_completed']),
        asInt(json['tasks_validated']),
        asInt(json['tasks_rejected']),
      );
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

class CleaningTask {
  final String id;
  final String residenceTitle;
  final String city;
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
  final List<(String url, String label)> photos;

  const CleaningTask({
    required this.id,
    required this.residenceTitle,
    required this.city,
    required this.status,
    required this.rejectionReason,
    required this.notes,
    required this.photos,
    this.agentId,
    this.agentName,
    this.controllerId,
    this.controllerName,
    this.nextCheckIn,
    this.startedAt,
    this.completedAt,
    this.validatedAt,
  });

  factory CleaningTask.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? map(String k) =>
        (json[k] as Map?)?.cast<String, dynamic>();
    return CleaningTask(
      id: json['id'].toString(),
      residenceTitle: map('residence')?['title']?.toString() ?? 'Logement',
      city: map('residence')?['city']?.toString() ?? '',
      status: TaskStatusX.parse(json['status']?.toString()),
      agentId: json['assigned_agent_id']?.toString(),
      agentName: map('assigned_agent')?['full_name']?.toString(),
      controllerId: json['assigned_controller_id']?.toString(),
      controllerName: map('assigned_controller')?['full_name']?.toString(),
      nextCheckIn: asDate(json['next_checkin']),
      startedAt: asDate(json['started_at']),
      completedAt: asDate(json['completed_at']),
      validatedAt: asDate(json['validated_at']),
      rejectionReason: json['rejection_reason']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      photos: ((json['photos'] as List?) ?? const [])
          .map((e) => (
                (e as Map)['url']?.toString() ?? '',
                e['label']?.toString() ?? '',
              ))
          .toList(),
    );
  }
}
