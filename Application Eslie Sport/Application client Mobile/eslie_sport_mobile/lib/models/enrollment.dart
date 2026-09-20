import 'package:intl/intl.dart';

class EnrollmentRequest {
  final String userName;
  final String userWhatsapp;
  final String slotId;
  final DateTime specificDate;
  final String? sessionType;
  final String? paymentType;
  final double? amountPaid;
  final String? feedback;

  const EnrollmentRequest({
    required this.userName,
    required this.userWhatsapp,
    required this.slotId,
    required this.specificDate,
    this.sessionType,
    this.paymentType,
    this.amountPaid,
    this.feedback,
  });

  Map<String, dynamic> toJson() => {
        'user_name': userName,
        'user_whatsapp': userWhatsapp,
        'slot_id': slotId,
        'specific_date': DateFormat('yyyy-MM-dd').format(specificDate),
        if (sessionType != null) 'session_type': sessionType,
        if (paymentType != null) 'payment_type': paymentType,
        if (amountPaid != null) 'amount_paid': amountPaid,
        if (feedback != null && feedback!.isNotEmpty) 'feedback': feedback,
      };
}

class Enrollment {
  final String id;
  final String userName;
  final String userWhatsapp;
  final String slotId;
  final DateTime specificDate;
  final String status;
  final String? paymentStatus;
  final double? amountPaid;

  const Enrollment({
    required this.id,
    required this.userName,
    required this.userWhatsapp,
    required this.slotId,
    required this.specificDate,
    required this.status,
    this.paymentStatus,
    this.amountPaid,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: json['id'].toString(),
        userName: json['user_name'] as String? ?? '',
        userWhatsapp: json['user_whatsapp'] as String? ?? '',
        slotId: (json['slot_id'] ?? '').toString(),
        specificDate:
            DateTime.tryParse(json['specific_date']?.toString() ?? '') ??
                DateTime.now(),
        status: json['status'] as String? ?? 'pending',
        paymentStatus: json['payment_status'] as String?,
        amountPaid: (json['amount_paid'] as num?)?.toDouble(),
      );
}
