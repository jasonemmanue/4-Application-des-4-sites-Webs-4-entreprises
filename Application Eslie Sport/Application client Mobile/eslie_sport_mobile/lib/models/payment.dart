enum PaymentOperator { wave, orangeMoney, mtnMobileMoney }

extension PaymentOperatorX on PaymentOperator {
  String get code => switch (this) {
        PaymentOperator.wave => 'wave',
        PaymentOperator.orangeMoney => 'orange_money',
        PaymentOperator.mtnMobileMoney => 'mtn_mobile_money',
      };

  String get label => switch (this) {
        PaymentOperator.wave => 'Wave',
        PaymentOperator.orangeMoney => 'Orange Money',
        PaymentOperator.mtnMobileMoney => 'MTN Mobile Money',
      };

  String? get requiredPrefix => switch (this) {
        PaymentOperator.orangeMoney => '07',
        PaymentOperator.mtnMobileMoney => '05',
        PaymentOperator.wave => null,
      };

  static PaymentOperator? fromCode(String code) {
    for (final op in PaymentOperator.values) {
      if (op.code == code) return op;
    }
    return null;
  }
}

enum PaymentStatus { pending, processing, completed, failed, cancelled, expired }

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'completed' || 'success' || 'succeeded' || 'paid' =>
        PaymentStatus.completed,
      'failed' || 'error' => PaymentStatus.failed,
      'cancelled' || 'canceled' => PaymentStatus.cancelled,
      'expired' || 'timeout' => PaymentStatus.expired,
      'processing' || 'in_progress' => PaymentStatus.processing,
      _ => PaymentStatus.pending,
    };
  }
}

class PaymentInit {
  final String reference;
  final String paymentUrl;
  final double amount;
  final double amountTotal;
  final String currency;
  final String method;
  final String mode;
  final String status;
  final DateTime? expiresAt;
  final int? expiresIn;

  const PaymentInit({
    required this.reference,
    required this.paymentUrl,
    required this.amount,
    required this.amountTotal,
    required this.currency,
    required this.method,
    required this.mode,
    required this.status,
    this.expiresAt,
    this.expiresIn,
  });

  factory PaymentInit.fromJson(Map<String, dynamic> json) => PaymentInit(
        reference: json['reference'] as String,
        paymentUrl: json['payment_url'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'XOF',
        method: json['method'] as String? ?? '',
        mode: json['mode'] as String? ?? 'production',
        status: json['status'] as String? ?? 'pending',
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        expiresIn: (json['expires_in'] as num?)?.toInt(),
      );
}

class PaymentStatusResponse {
  final String reference;
  final PaymentStatus status;
  final String method;
  final String mode;
  final double amount;
  final double amountTotal;
  final String currency;
  final DateTime? paidAt;
  final String? error;
  final bool expired;
  final int? expiresIn;
  final String? paymentUrl;
  final String? memberName;
  final String? activityName;
  final String? subscriptionName;

  const PaymentStatusResponse({
    required this.reference,
    required this.status,
    required this.method,
    required this.mode,
    required this.amount,
    required this.amountTotal,
    required this.currency,
    this.paidAt,
    this.error,
    this.expired = false,
    this.expiresIn,
    this.paymentUrl,
    this.memberName,
    this.activityName,
    this.subscriptionName,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) =>
      PaymentStatusResponse(
        reference: json['reference'] as String,
        status: PaymentStatusX.fromString(json['status'] as String? ?? 'pending'),
        method: json['method'] as String? ?? '',
        mode: json['mode'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'XOF',
        paidAt: json['paid_at'] != null
            ? DateTime.tryParse(json['paid_at'] as String)
            : null,
        error: json['error'] as String?,
        expired: json['expired'] as bool? ?? false,
        expiresIn: (json['expires_in'] as num?)?.toInt(),
        paymentUrl: json['payment_url'] as String?,
        memberName: json['member_name'] as String?,
        activityName: json['activity_name'] as String?,
        subscriptionName: json['subscription_name'] as String?,
      );
}
