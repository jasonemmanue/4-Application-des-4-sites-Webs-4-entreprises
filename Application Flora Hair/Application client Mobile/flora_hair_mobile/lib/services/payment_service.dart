import 'dart:async';

import 'package:dio/dio.dart';
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

  Future<Map<String, dynamic>> fetchConfig() async {
    final res = await _api.dio.get('/payments/config');
    return (res.data as Map<String, dynamic>?) ?? <String, dynamic>{};
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
      final res = await _api.dio.post('/payments/init',
          data: data,
          options: Options(headers: {'X-Cle-Demande': idempotencyKey}));
      return PaymentInit.fromJson(res.data as Map<String, dynamic>);
    } finally {
      _initInProgress = false;
    }
  }

  /// `GET /payments/{transaction_id}`
  Future<PaymentStatusResponse> checkStatus(String reference) async {
    final res = await _api.dio.get('/payments/$reference');
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
    final res = await _api.dio.post(
      '/payments/$reference/retry',
      data: data,
      options: Options(headers: {'X-Cle-Demande': idempotencyKey}),
    );
    return PaymentInit.fromJson(res.data as Map<String, dynamic>);
  }

  /// `POST /payments/{transaction_id}/cancel`
  Future<void> cancel(String reference) async {
    await _api.dio.post('/payments/$reference/cancel');
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
        if (status.status == PaymentStatus.success ||
            status.status == PaymentStatus.failed ||
            status.status == PaymentStatus.cancelled ||
            status.status == PaymentStatus.expired) {
          return;
        }
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

  /// Valide le numero selon l'operateur.
  static String? validatePhoneForOperator(
      String phone, PaymentOperator operator) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Numero trop court';
    final local =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    final prefix = operator.expectedPrefix;
    if (prefix != null && !local.startsWith(prefix)) {
      return 'Le numero ${operator.label} doit commencer par $prefix';
    }
    return null;
  }

  /// Formate en international +225XXXXXXXXXX.
  static String toInternational(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('225')) return '+$digits';
    if (digits.length == 10) return '+225$digits';
    if (digits.length == 8) return '+225$digits';
    return '+$digits';
  }
}

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => PaymentService(ref.watch(apiClientProvider)),
);
