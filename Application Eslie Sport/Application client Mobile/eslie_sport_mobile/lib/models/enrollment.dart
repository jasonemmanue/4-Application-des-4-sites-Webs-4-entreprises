import 'package:intl/intl.dart';

/// Formule du registre de la salle (`payment_type`). L'API en deduit l'acompte :
/// sans elle, aucun montant n'est calculable et le paiement est refuse.
enum EnrollmentFormula {
  session('Séance', 'Séance', 'Seance individuelle / collective', 3000),
  monthly('Abonnée mensuel', 'Abonnement mensuel', 'Mensualite', 30000),
  kungFu('Abonnement de karaté', 'Abonnement Kung-Fu Wushu',
      'Kung-Fu Wushu — Mensuel', 10000),
  boxing('Abonnement de box', 'Abonnement Boxe & Kick-boxing',
      'Boxe & Kick Boxing — Mensuel', 15000);

  const EnrollmentFormula(
      this.apiValue, this.label, this.catalogName, this.fallbackPrice);

  /// Valeur exacte attendue par `PaymentType` cote FastAPI.
  final String apiValue;
  final String label;

  /// Ligne du catalogue `subscriptions` qui porte le tarif, reglable au
  /// back-office. Meme table que `FORMULE_VERS_ABONNEMENT` cote serveur.
  final String catalogName;
  final int fallbackPrice;
}

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
  final double? depositAmount;
  final double? amountDue;

  /// `pending_payment` : la place n'est prise qu'au reglement de l'acompte.
  bool get awaitsPayment => status == 'pending_payment';

  const Enrollment({
    required this.id,
    required this.userName,
    required this.userWhatsapp,
    required this.slotId,
    required this.specificDate,
    required this.status,
    this.paymentStatus,
    this.amountPaid,
    this.depositAmount,
    this.amountDue,
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
        depositAmount: (json['deposit_amount'] as num?)?.toDouble(),
        amountDue: (json['amount_due'] as num?)?.toDouble(),
      );
}
