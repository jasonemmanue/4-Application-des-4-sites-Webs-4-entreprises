/// Orchestration cote client du paiement GeniusPay / Stripe.
///
/// Le backend est la seule source de verite : montant, expiration et statut
/// sont recalcules cote serveur. Ce service se limite a :
///   * normaliser le numero (+225XXXXXXXXXX) et valider le prefixe operateur ;
///   * ouvrir le guichet dans le navigateur externe (Wave, carte, USSD) ;
///   * poller `/payments/{reference}` jusqu'a un etat terminal ou expiration.
///
/// Le polling n'annule PAS le paiement quand il expire cote client : le
/// backend peut encore recevoir la notification de GeniusPay apres coup.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService(this._api);

  final ApiClient _api;

  static const Duration pollInterval = Duration(seconds: 3);
  static const Duration pollIntervalCard = Duration(seconds: 5);

  /// Marge apres l'expiration annoncee : la notification de l'operateur peut
  /// arriver juste apres la fin de session.
  static const Duration pollGrace = Duration(seconds: 20);
  static const int defaultSessionSeconds = 300;

  String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('225')) return '+$digits';
    return '+225$digits';
  }

  /// Message d'erreur a afficher, ou null si le numero convient. Memes regles
  /// que `_verifier_le_numero` cote backend, pour refuser avant l'appel.
  String? phoneError(PaymentOperator op, String raw) {
    final national = normalizePhone(raw).replaceFirst('+225', '');
    if (!RegExp(r'^[0-9]{10}$').hasMatch(national)) {
      return 'Un numéro ivoirien à 10 chiffres est attendu.';
    }
    final prefixes = op.allowedPrefixes;
    if (prefixes.isNotEmpty && !prefixes.any(national.startsWith)) {
      return 'Ce numéro ne correspond pas à ${op.label} '
          '(${prefixes.join(', ')}).';
    }
    return null;
  }

  int computeDeposit(num totalAmount, {int percent = 50}) =>
      (totalAmount * percent / 100).round();

  Future<PaymentConfig> loadConfig() async {
    final raw = await _api.getPaymentConfig();
    return PaymentConfig.fromJson(raw);
  }

  Future<PaymentInit> initiate({
    String? enrollmentId,
    String? subscriptionOrderId,
    required PaymentOperator operator,
    required String paymentPhone,
  }) {
    return _api.initPayment(
      enrollmentId: enrollmentId,
      subscriptionOrderId: subscriptionOrderId,
      operator: operator,
      paymentPhone: paymentPhone,
    );
  }

  Future<bool> openCheckoutUrl(String? url) async {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Stream<PaymentStatusResponse> pollStatus(
    String reference, {
    bool isCard = false,
    int? expiresIn,
  }) async* {
    final maxDuration =
        Duration(seconds: expiresIn ?? defaultSessionSeconds) + pollGrace;
    final interval = isCard ? pollIntervalCard : pollInterval;
    final deadline = DateTime.now().add(maxDuration);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final status = await _api.getPaymentStatus(reference);
        yield status;
        if (isTerminal(status)) return;
      } on ApiException catch (e) {
        if (e.isNotFound) return;
      } catch (_) {}
      await Future<void>.delayed(interval);
    }
  }

  bool isTerminal(PaymentStatusResponse s) => s.expired || _isTerminal(s.status);

  bool _isTerminal(PaymentStatus s) =>
      s == PaymentStatus.completed ||
      s == PaymentStatus.failed ||
      s == PaymentStatus.cancelled ||
      s == PaymentStatus.expired;

  Future<PaymentStatusResponse> refresh(String reference) =>
      _api.getPaymentStatus(reference);

  Future<PaymentStatusResponse> cancel(String reference) =>
      _api.cancelPayment(reference);

  /// Le renvoi ouvre une tentative neuve : la reponse porte une NOUVELLE
  /// reference, que l'appelant doit suivre a la place de l'ancienne.
  Future<PaymentStatusResponse> resendPush(String reference) =>
      _api.resendPush(reference);
}

class PaymentConfig {
  final bool enabled;
  final String mode;
  final String provider;
  final double depositRate;
  final int sessionSeconds;
  final List<PaymentMethodInfo> methods;

  const PaymentConfig({
    required this.enabled,
    required this.mode,
    required this.provider,
    required this.depositRate,
    required this.sessionSeconds,
    required this.methods,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    final rawMethods = json['methods'] as List? ?? [];
    return PaymentConfig(
      enabled: json['enabled'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'sandbox',
      provider: json['provider'] as String? ?? 'geniuspay',
      depositRate: (json['deposit_rate'] as num?)?.toDouble() ?? 0.5,
      sessionSeconds: (json['session_seconds'] as num?)?.toInt() ?? 360,
      methods: rawMethods
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodInfo.fromJson)
          .toList(growable: false),
    );
  }

  List<PaymentOperator> get operators {
    return methods
        .map((m) => PaymentOperatorX.fromCode(m.value))
        .whereType<PaymentOperator>()
        .toList(growable: false);
  }
}

class PaymentMethodInfo {
  final String value;
  final String label;
  final String provider;
  final bool needsPhone;

  const PaymentMethodInfo({
    required this.value,
    required this.label,
    required this.provider,
    required this.needsPhone,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
      provider: json['provider'] as String? ?? 'geniuspay',
      needsPhone: json['needs_phone'] as bool? ?? true,
    );
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(apiClientProvider));
});

final paymentConfigProvider = FutureProvider.autoDispose<PaymentConfig>((ref) {
  return ref.watch(paymentServiceProvider).loadConfig();
});
