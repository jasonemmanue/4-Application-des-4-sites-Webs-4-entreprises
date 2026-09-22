enum PaymentOperator { wave, orangeMoney, mtnMoney }

extension PaymentOperatorX on PaymentOperator {
  String get code {
    switch (this) {
      case PaymentOperator.wave:
        return 'wave';
      case PaymentOperator.orangeMoney:
        return 'orange_money';
      case PaymentOperator.mtnMoney:
        return 'mtn_money';
    }
  }

  String get label {
    switch (this) {
      case PaymentOperator.wave:
        return 'Wave';
      case PaymentOperator.orangeMoney:
        return 'Orange Money';
      case PaymentOperator.mtnMoney:
        return 'MTN Mobile Money';
    }
  }

  String? get expectedPrefix {
    switch (this) {
      case PaymentOperator.orangeMoney:
        return '07';
      case PaymentOperator.mtnMoney:
        return '05';
      case PaymentOperator.wave:
        return null;
    }
  }
}

enum PaymentStatus { pending, processing, success, failed, cancelled, expired }

PaymentStatus paymentStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'success':
    case 'paid':
    case 'completed':
      return PaymentStatus.success;
    case 'failed':
    case 'error':
      return PaymentStatus.failed;
    case 'cancelled':
    case 'canceled':
      return PaymentStatus.cancelled;
    case 'expired':
    case 'timeout':
      return PaymentStatus.expired;
    case 'processing':
    case 'in_progress':
      return PaymentStatus.processing;
    default:
      return PaymentStatus.pending;
  }
}

/// Reponse a `POST /payments/init`.
///
/// Cote backend : { transaction_id, payment_url, amount, currency, mode }.
class PaymentInit {
  const PaymentInit({
    required this.transactionId,
    required this.paymentUrl,
    this.amount,
    this.currency = 'XOF',
    this.mode = 'production',
  });

  final String transactionId;
  final String paymentUrl;
  final double? amount;
  final String currency;
  final String mode;

  // Alias historiques utilises par le code UI existant.
  String get reference => transactionId;
  String? get checkoutUrl => paymentUrl.isEmpty ? null : paymentUrl;
  PaymentStatus get status => PaymentStatus.pending;

  factory PaymentInit.fromJson(Map<String, dynamic> json) => PaymentInit(
        transactionId: (json['transaction_id'] ?? '').toString(),
        paymentUrl: (json['payment_url'] ?? '') as String,
        amount: (json['amount'] as num?)?.toDouble(),
        currency: (json['currency'] as String?) ?? 'XOF',
        mode: (json['mode'] as String?) ?? 'production',
      );
}

/// Reponse a `GET /payments/{ref}`.
class PaymentStatusResponse {
  const PaymentStatusResponse({
    required this.reference,
    required this.status,
    this.message,
    this.amount,
    this.currency = 'XOF',
    this.operator,
    this.operatorLabel,
    this.paidAt,
    this.paymentUrl,
    this.bookingDate,
    this.bookingTime,
    this.serviceName,
    this.clientFirstName,
    this.remainingAmount,
  });

  final String reference;
  final PaymentStatus status;
  final String? message;
  final double? amount;
  final String currency;
  final String? operator;
  final String? operatorLabel;
  final DateTime? paidAt;
  final String? paymentUrl;
  final String? bookingDate;
  final String? bookingTime;
  final String? serviceName;
  final String? clientFirstName;
  final double? remainingAmount;

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) =>
      PaymentStatusResponse(
        reference: (json['transaction_id'] ?? json['reference'] ?? '')
            .toString(),
        status: paymentStatusFromString(
          (json['status'] as String?) ?? 'pending',
        ),
        message: json['message'] as String?,
        amount: (json['amount'] as num?)?.toDouble(),
        currency: (json['currency'] as String?) ?? 'XOF',
        operator: json['operator'] as String?,
        operatorLabel: json['operator_label'] as String?,
        paidAt: json['paid_at'] != null
            ? DateTime.tryParse(json['paid_at'] as String)
            : null,
        paymentUrl: json['payment_url'] as String?,
        bookingDate: json['booking_date'] as String?,
        bookingTime: json['booking_time'] as String?,
        serviceName: json['service_name'] as String?,
        clientFirstName: json['client_first_name'] as String?,
        remainingAmount: (json['remaining_amount'] as num?)?.toDouble(),
      );
}
