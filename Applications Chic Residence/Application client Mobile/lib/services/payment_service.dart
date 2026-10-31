import '../models/payment.dart';
import 'api_client.dart';

/// Routes réelles du backend :
///  GET  /payments/config                  -> moyens proposés
///  POST /payments/init                    -> première tentative
///  GET  /payments/{reference}             -> statut
///  POST /payments/{reference}/retry       -> autre opérateur, même réservation
///  POST /payments/{reference}/push/resend -> renvoi USSD (nouvelle référence)
///  POST /payments/{reference}/cancel      -> abandonne la tentative
class PaymentService {
  PaymentService(this._api);
  final ApiClient _api;

  bool _initInProgress = false;

  Future<PaymentOptions> options() async {
    final res = await _api.dio.get('/payments/config');
    return PaymentOptions.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// Nouvelle tentative : `previousReference` nul pour la première, sinon la
  /// réservation est retrouvée par la référence précédente. Sans cela, changer
  /// d'opérateur créerait une seconde réservation.
  Future<PaymentAttempt> start({
    required String bookingId,
    String? previousReference,
    required PaymentChannel channel,
    required String phone,
  }) async {
    if (_initInProgress) {
      throw ApiException('Paiement déjà en cours. Patientez.');
    }
    _initInProgress = true;
    try {
      // Orange / MTN : `window_opened` faux, l'API exécute elle-même la page du
      // guichet qui fait partir le message. Wave / carte : l'application ouvre
      // cette page dans le navigateur.
      final body = {
        'channel': channel.apiValue,
        'customer_phone': channel == PaymentChannel.card ? '' : phone,
        'window_opened': !channel.usesPush,
      };
      final res = previousReference == null
          ? await _api.dio.post('/payments/init',
              data: {...body, 'booking_id': bookingId})
          : await _api.dio
              .post('/payments/$previousReference/retry', data: body);
      return PaymentAttempt.fromJson((res.data as Map).cast<String, dynamic>());
    } finally {
      _initInProgress = false;
    }
  }

  Future<PaymentAttempt> status(String reference) async {
    final res = await _api.dio.get('/payments/$reference');
    return PaymentAttempt.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// La réponse porte une NOUVELLE référence, à suivre désormais.
  Future<PaymentAttempt> resendPush(String reference) async {
    final res = await _api.dio.post('/payments/$reference/push/resend');
    return PaymentAttempt.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> cancel(String reference) async {
    await _api.dio.post('/payments/$reference/cancel');
  }
}
