enum PaymentChannel { wave, orangeMoney, mtnMoney, card }

extension PaymentChannelX on PaymentChannel {
  String get label {
    switch (this) {
      case PaymentChannel.wave:
        return 'Wave';
      case PaymentChannel.orangeMoney:
        return 'Orange Money';
      case PaymentChannel.mtnMoney:
        return 'MTN Mobile Money';
      case PaymentChannel.card:
        return 'Carte bancaire';
    }
  }

  /// Nom court pour les pastilles de sélection.
  String get shortLabel {
    switch (this) {
      case PaymentChannel.wave:
        return 'Wave';
      case PaymentChannel.orangeMoney:
        return 'Orange';
      case PaymentChannel.mtnMoney:
        return 'MTN';
      case PaymentChannel.card:
        return 'Carte';
    }
  }

  /// Clé **exacte** attendue par l'API (`CHANNELS` du backend). À NE PAS
  /// dériver de `name` : les clés backend sont `orange_money` / `mtn_money`,
  /// pas `orange` / `mtn` — l'ancien `=> name` faisait rejeter ces paiements.
  String get apiValue {
    switch (this) {
      case PaymentChannel.wave:
        return 'wave';
      case PaymentChannel.orangeMoney:
        return 'orange_money';
      case PaymentChannel.mtnMoney:
        return 'mtn_money';
      case PaymentChannel.card:
        return 'card';
    }
  }

  /// Préfixe national du numéro Mobile Money (vide = aucun contrôle).
  String get prefix {
    switch (this) {
      case PaymentChannel.orangeMoney:
        return '07';
      case PaymentChannel.mtnMoney:
        return '05';
      case PaymentChannel.wave:
      case PaymentChannel.card:
        return '';
    }
  }

  /// Paiement par notification USSD (Orange, MTN) plutôt que par page web.
  bool get usesPush =>
      this == PaymentChannel.orangeMoney || this == PaymentChannel.mtnMoney;

  /// La carte bancaire se règle par redirection web sécurisée et n'exige
  /// aucun numéro local — contrairement aux canaux Mobile Money.
  bool get needsPhone => this != PaymentChannel.card;
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
          (e) => e.apiValue == (json['channel']?.toString() ?? '').toLowerCase(),
          orElse: () => PaymentChannel.wave,
        ),
      );
}
