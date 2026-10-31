import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService(this._api);
  final ApiClient _api;
  static const _uuid = Uuid();

  bool _initInProgress = false;

  /// Moyens ouverts par le back-office : c'est lui qui décide, pas l'application.
  Future<PaymentConfig> fetchConfig() async {
    final res = await _api.get('/payments/config');
    return PaymentConfig.fromJson(res.data as Map<String, dynamic>);
  }

  /// Initialise un paiement pour la reservation donnee.
  ///
  /// Verrou anti-double clic + header X-Cle-Demande (idempotence).
  Future<PaymentInit> initPayment({
    required String bookingId,
    required PaymentOperator operator,
    String? phone,
    int? amount,
  }) async {
    if (_initInProgress) {
      throw ApiException('Paiement deja en cours. Patientez.');
    }
    _initInProgress = true;
    try {
      final idempotencyKey = _uuid.v4();
      final data = <String, dynamic>{
        'booking_id': bookingId,
        'method': operator.code,
      };
      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
      }
      final res = await _api.post('/payments/init',
          data: data, headers: {'X-Cle-Demande': idempotencyKey});
      return PaymentInit.fromJson(res.data as Map<String, dynamic>);
    } finally {
      _initInProgress = false;
    }
  }

  /// `GET /payments/{transaction_id}`
  Future<PaymentStatusResponse> checkStatus(String reference) async {
    final res = await _api.get('/payments/$reference');
    return PaymentStatusResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// `POST /payments/{transaction_id}/retry` — avec cle d'idempotence.
  Future<PaymentInit> retry({
    required String reference,
    required PaymentOperator operator,
    String? phone,
  }) async {
    final idempotencyKey = _uuid.v4();
    final data = <String, dynamic>{
      'method': operator.code,
    };
    if (phone != null && phone.isNotEmpty) {
      data['phone'] = phone;
    }
    final res = await _api.post(
      '/payments/$reference/retry',
      data: data,
      headers: {'X-Cle-Demande': idempotencyKey},
    );
    return PaymentInit.fromJson(res.data as Map<String, dynamic>);
  }

  /// `POST /payments/{transaction_id}/cancel`
  Future<void> cancel(String reference) async {
    await _api.post('/payments/$reference/cancel');
  }

  /// `POST /payments/{transaction_id}/push` — renvoie la demande de validation
  /// Mobile Money sur le téléphone.
  Future<void> resendPush(String reference) async {
    await _api.post('/payments/$reference/push');
  }

  /// Polling toutes les [interval] secondes, jusqu'a un etat final ou timeout.
  Stream<PaymentStatusResponse> pollStatus(
    String reference, {
    Duration interval =
        const Duration(seconds: ApiConfig.paymentPollingIntervalSeconds),
    Duration timeout =
        const Duration(seconds: ApiConfig.paymentTimeoutSeconds),
  }) async* {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final status = await checkStatus(reference);
        yield status;
        if (status.status.isFinal) return;
      } catch (_) {
        // ignore et re-essaie
      }
      await Future<void>.delayed(interval);
    }
    yield PaymentStatusResponse(
      reference: reference,
      status: PaymentStatus.expired,
      message: 'Delai de paiement depasse',
    );
  }

  /// Même règle que `phone_error` côté backend : dix chiffres, rien de plus.
  ///
  /// Le préfixe n'est pas contrôlé : la portabilité existe en Côte d'Ivoire, et
  /// refuser un `01` sur MTN bloquerait un paiement légitime.
  static String? validatePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00225')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('225')) {
      digits = digits.substring(3);
    }
    return digits.length == 10
        ? null
        : 'Saisissez un numéro ivoirien à dix chiffres.';
  }

  /// Formate en international +225XXXXXXXXXX.
  static String toInternational(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00225')) return '+${digits.substring(2)}';
    if (digits.startsWith('225')) return '+$digits';
    return '+225$digits';
  }
}

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => PaymentService(ref.watch(apiClientProvider)),
);

final paymentConfigProvider = FutureProvider<PaymentConfig>(
  (ref) => ref.watch(paymentServiceProvider).fetchConfig(),
);
