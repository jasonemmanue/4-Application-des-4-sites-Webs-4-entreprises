/// Orchestration cote client du paiement GeniusPay.
///
/// Le backend est la seule source de verite : montant, expiration et statut
/// sont recalcules cote serveur. Ce service se limite a :
///   * normaliser le numero (+225XXXXXXXXXX) et valider le prefixe operateur ;
///   * ouvrir le guichet dans le navigateur externe (Wave ou USSD) ;
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

  /// Cadence de sondage recommandee cote site web : 3-4 s.
  static const Duration pollInterval = Duration(seconds: 3);

  /// Duree maximale de sondage cote client. Le backend impose une expiration
  /// distincte (60 s par defaut, `session_seconds` de `/payments/config`).
  static const Duration pollMaxDuration = Duration(seconds: 90);

  /// Normalise un numero saisi par l'utilisateur en `+225XXXXXXXXXX`.
  String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('225')) return '+$digits';
    // On accepte un numero national a 10 chiffres et on ajoute l'indicatif.
    return '+225$digits';
  }

  /// Verifie que le prefixe local (07/05) correspond a l'operateur choisi.
  /// Wave n'impose aucun prefixe (portefeuille QR).
  bool validatePhoneForOperator(PaymentOperator op, String normalizedPhone) {
    final prefix = op.requiredPrefix;
    if (prefix == null) return true;
    final national = normalizedPhone.replaceFirst('+225', '');
    return national.startsWith(prefix);
  }

  /// L'acompte cote client est indicatif — le backend recalcule.
  int computeDeposit(num totalAmount, {int percent = 50}) =>
      (totalAmount * percent / 100).round();

  Future<Map<String, dynamic>> loadConfig() => _api.getPaymentConfig();

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

  /// Ouvre le guichet (URL Wave ou page hebergee) dans le navigateur externe.
  /// Retourne `false` si l'URL est vide ou si le lien ne peut pas s'ouvrir.
  Future<bool> openCheckoutUrl(String? url) async {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Flux de statuts jusqu'a un etat terminal ou l'expiration cote client.
  /// L'appelant peut break/cancel librement — chaque tick releve `getPaymentStatus`.
  Stream<PaymentStatusResponse> pollStatus(String reference) async* {
    final deadline = DateTime.now().add(pollMaxDuration);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final status = await _api.getPaymentStatus(reference);
        yield status;
        if (_isTerminal(status.status) || status.expired) return;
      } on ApiException catch (e) {
        // 404 = reference inconnue : inutile de continuer.
        if (e.isNotFound) return;
      } catch (_) {
        // Erreur reseau transitoire : on retente au tick suivant.
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  bool _isTerminal(PaymentStatus s) =>
      s == PaymentStatus.completed ||
      s == PaymentStatus.failed ||
      s == PaymentStatus.cancelled ||
      s == PaymentStatus.expired;

  Future<PaymentStatusResponse> refresh(String reference) =>
      _api.getPaymentStatus(reference);

  Future<PaymentStatusResponse> cancel(String reference) =>
      _api.cancelPayment(reference);

  Future<PaymentStatusResponse> resendPush(String reference) =>
      _api.resendPush(reference);
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(apiClientProvider));
});
