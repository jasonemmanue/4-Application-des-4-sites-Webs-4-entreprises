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

  /// Clé **exacte** attendue par l'API (`CHANNELS` du backend). À NE PAS
  /// dériver de `name` : les clés backend sont `orange_money` / `mtn_money`,
  /// pas `orange` / `mtn` : l'ancien `=> name` faisait rejeter ces paiements.
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

  /// Fichier officiel de l'opérateur, copié de
  /// `frontend/public/images/paiement/` du site. Les extensions diffèrent.
  String get logoAsset {
    switch (this) {
      case PaymentChannel.wave:
        return 'assets/paiement/wave.png';
      case PaymentChannel.orangeMoney:
        return 'assets/paiement/orange-money.svg';
      case PaymentChannel.mtnMoney:
        return 'assets/paiement/mtn-momo.png';
      case PaymentChannel.card:
        return 'assets/paiement/carte-bancaire.svg';
    }
  }

  /// Paiement par demande USSD (Orange, MTN) plutôt que par page web.
  bool get usesPush =>
      this == PaymentChannel.orangeMoney || this == PaymentChannel.mtnMoney;

  /// Consignes à afficher pendant l'attente : sans elles le client attend un
  /// menu qui ne vient pas, et la demande expire (voir `docs/PAIEMENT.md`).
  List<String> get steps {
    switch (this) {
      case PaymentChannel.mtnMoney:
        return const [
          'Vous recevez un SMS de demande de débit.',
          'Composez *133#, puis 1, puis 1.',
          'Saisissez votre code secret MoMo pour valider.',
        ];
      case PaymentChannel.orangeMoney:
        return const [
          'Vous recevez une demande de paiement Orange Money.',
          'Composez #144# si le menu ne s\'ouvre pas tout seul.',
          'Saisissez votre code secret pour valider.',
        ];
      case PaymentChannel.wave:
        return const [
          'La page Wave s\'ouvre sur votre téléphone.',
          'Validez le paiement dans l\'application Wave.',
          'Revenez ici : la confirmation s\'affiche toute seule.',
        ];
      case PaymentChannel.card:
        return const [
          'La page sécurisée s\'ouvre dans votre navigateur.',
          'Saisissez les informations de votre carte Visa ou Mastercard.',
          'Revenez ici : la confirmation s\'affiche toute seule.',
        ];
    }
  }

  static PaymentChannel? tryParse(String? v) {
    for (final c in PaymentChannel.values) {
      if (c.apiValue == v) return c;
    }
    return null;
  }
}

/// `succeeded` est la valeur de l'enum PostgreSQL `payment_status`. L'ancien
/// parseur ne connaissait que `success` : un paiement réussi restait donc
/// affiché « en attente » pour toujours.
enum PaymentStatus { pending, success, failed, cancelled, expired }

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus parse(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'succeeded':
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'expired':
        return PaymentStatus.expired;
      default:
        // Un statut inconnu reste « en attente », jamais « échoué » : conclure
        // à l'échec annulerait un paiement peut-être réussi.
        return PaymentStatus.pending;
    }
  }
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  // L'API sérialise ses `Decimal` en texte : `"42500.00"`.
  return int.tryParse(v.toString().split('.').first) ?? 0;
}

/// Réponse de `GET /payments/config` : pilote ce que propose l'écran de
/// paiement. Retirer un moyen par `PAYMENT_CHANNELS` côté serveur le fait
/// disparaître ici sans nouvelle version de l'application.
class PaymentOptions {
  final bool enabled;
  final String mode;
  final int depositPercent;
  final List<PaymentChannel> channels;
  final Map<PaymentChannel, List<String>> prefixes;
  final Set<PaymentChannel> requiresPhone;

  const PaymentOptions({
    required this.enabled,
    required this.mode,
    required this.depositPercent,
    required this.channels,
    required this.prefixes,
    required this.requiresPhone,
  });

  factory PaymentOptions.fromJson(Map<String, dynamic> json) {
    final channels = <PaymentChannel>[];
    final prefixes = <PaymentChannel, List<String>>{};
    final requires = <PaymentChannel>{};
    for (final raw in (json['channels'] as List?) ?? const []) {
      final m = (raw as Map).cast<String, dynamic>();
      final c = PaymentChannelX.tryParse(m['key']?.toString());
      if (c == null) continue;
      channels.add(c);
      prefixes[c] = ((m['phone_prefixes'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      if (m['requires_phone'] == true) requires.add(c);
    }
    return PaymentOptions(
      enabled: json['enabled'] == true,
      mode: json['mode']?.toString() ?? 'unknown',
      depositPercent: _toInt(json['deposit_percent']),
      channels: channels,
      prefixes: prefixes,
      requiresPhone: requires,
    );
  }
}

/// Où en est le message USSD (Orange, MTN). Un repère d'affichage, jamais une
/// preuve de paiement : le verdict reste le statut.
class PushInfo {
  final String status; // queued | opening | sent | failed | closed
  final int resendIn;
  final bool canResend;
  final String? error;

  const PushInfo({
    required this.status,
    required this.resendIn,
    required this.canResend,
    this.error,
  });

  bool get failed => status == 'failed';

  static PushInfo? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    return PushInfo(
      status: raw['status']?.toString() ?? 'queued',
      resendIn: _toInt(raw['resend_in']),
      canResend: raw['can_resend'] == true,
      error: raw['error']?.toString(),
    );
  }
}

/// `PaymentInitResponse` et `PaymentStatusOut` : mêmes champs utiles.
class PaymentAttempt {
  final String reference;
  final String paymentUrl;
  final PaymentStatus status;
  final int amount;
  final int remaining;
  final PaymentChannel channel;
  final String mode;
  final String failureReason;
  final PushInfo? push;

  const PaymentAttempt({
    required this.reference,
    required this.paymentUrl,
    required this.status,
    required this.amount,
    required this.remaining,
    required this.channel,
    required this.mode,
    required this.failureReason,
    this.push,
  });

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) => PaymentAttempt(
        reference: json['reference']?.toString() ?? '',
        paymentUrl: json['payment_url']?.toString() ?? '',
        status: PaymentStatusX.parse(json['status']?.toString()),
        amount: _toInt(json['amount']),
        remaining: _toInt(json['remaining_amount']),
        channel: PaymentChannelX.tryParse(json['channel']?.toString()) ??
            PaymentChannel.wave,
        mode: json['mode']?.toString() ?? '',
        failureReason: json['failure_reason']?.toString() ?? '',
        push: PushInfo.fromJson(json['push']),
      );
}
