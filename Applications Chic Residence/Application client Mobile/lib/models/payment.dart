enum PaymentChannel { wave, orange, mtn }

extension PaymentChannelX on PaymentChannel {
  String get label {
    switch (this) {
      case PaymentChannel.wave:
        return 'Wave';
      case PaymentChannel.orange:
        return 'Orange Money';
      case PaymentChannel.mtn:
        return 'MTN Mobile Money';
    }
  }

  String get apiValue => name;

  String get prefix {
    switch (this) {
      case PaymentChannel.orange:
        return '07';
      case PaymentChannel.mtn:
        return '05';
      case PaymentChannel.wave:
        return '';
    }
  }
}

enum PaymentStatus { pending, processing, success, failed, cancelled, expired }

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus parse(String? v) => PaymentStatus.values.firstWhere(
        (e) => e.name == (v ?? '').toLowerCase(),
        orElse: () => PaymentStatus.pending,
      );
}

class PaymentInit {
  final String reference;
  final String? checkoutUrl;
  final PaymentStatus status;
  final int amount;
  final PaymentChannel channel;

  const PaymentInit({
    required this.reference,
    required this.status,
    required this.amount,
    required this.channel,
    this.checkoutUrl,
  });

  factory PaymentInit.fromJson(Map<String, dynamic> json) => PaymentInit(
        reference: json['reference']?.toString() ?? '',
        checkoutUrl: json['checkout_url']?.toString(),
        status: PaymentStatusX.parse(json['status']?.toString()),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        channel: PaymentChannel.values.firstWhere(
          (e) => e.name == (json['channel']?.toString() ?? '').toLowerCase(),
          orElse: () => PaymentChannel.wave,
        ),
      );
}
