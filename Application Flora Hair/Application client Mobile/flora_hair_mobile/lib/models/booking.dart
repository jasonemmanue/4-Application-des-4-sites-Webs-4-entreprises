class Booking {
  const Booking({
    this.id,
    required this.serviceId,
    required this.teamMemberId,
    required this.date,
    required this.timeSlot,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.notes,
    this.depositAmount = 0,
    this.depositStatus,
    this.status,
    this.reference,
  });

  final String? id;
  final String serviceId;
  final String teamMemberId;
  final DateTime date;
  final String timeSlot; // HH:MM
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? notes;
  final int depositAmount;
  final String? depositStatus;
  final String? status;
  final String? reference;

  // Alias historique
  String get startTime => timeSlot;

  Map<String, dynamic> toCreateJson() => <String, dynamic>{
        'service_id': serviceId,
        'team_member_id': teamMemberId,
        'date': _dateOnly(date),
        'time_slot': timeSlot,
        'client_name': customerName,
        'client_phone': customerPhone,
        'client_email': customerEmail ?? '',
        'notes': notes ?? '',
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id']?.toString(),
        serviceId: (json['service_id'] ?? '').toString(),
        teamMemberId: (json['team_member_id'] ?? '').toString(),
        date: DateTime.parse(json['date'] as String),
        timeSlot: (json['time_slot'] ?? json['start_time'] ?? '') as String,
        customerName: (json['client_name'] ?? json['customer_name'] ?? '')
            as String,
        customerPhone: (json['client_phone'] ?? json['customer_phone'] ?? '')
            as String,
        customerEmail: (json['client_email'] ?? json['customer_email']) as String?,
        notes: json['notes'] as String?,
        depositAmount: (json['deposit_amount'] as num?)?.toInt() ?? 0,
        depositStatus: json['deposit_status'] as String?,
        status: json['status'] as String?,
        // La reference publique du booking est son id (UUID) : le backend
        // n'expose pas un champ "reference" separe.
        reference: json['id']?.toString(),
      );
}
