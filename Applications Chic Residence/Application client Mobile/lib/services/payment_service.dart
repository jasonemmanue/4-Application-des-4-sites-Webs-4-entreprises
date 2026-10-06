import '../config/api_config.dart';
import '../models/payment.dart';
import 'api_client.dart';

/// URLs reelles du backend :
///  POST /payments/init                    -> initie
///  GET  /payments/{reference}             -> statut
///  POST /payments/{reference}/retry       -> reessai
///  POST /payments/{reference}/cancel      -> annule
class PaymentService {
  PaymentService(this._api);
  final ApiClient _api;

  Future<PaymentInit> init({
    required String bookingId,
    required PaymentChannel channel,
    required String phone,
  }) async {
    final res = await _api.dio.post('/payments/init', data: {
      'booking_id': bookingId,
      'channel': channel.apiValue,
      'customer_phone': phone,
    });
    return PaymentInit.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<PaymentStatus> status(String reference) async {
    final res = await _api.dio.get('/payments/$reference');
    final data = (res.data as Map).cast<String, dynamic>();
    return PaymentStatusX.parse(data['status']?.toString());
  }

  Future<PaymentInit> retry(String reference,
      {required PaymentChannel newChannel, required String newPhone}) async {
    final res = await _api.dio.post('/payments/$reference/retry', data: {
      'channel': newChannel.apiValue,
      'customer_phone': newPhone,
    });
    return PaymentInit.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> cancel(String reference) async {
    await _api.dio.post('/payments/$reference/cancel');
  }

  Stream<PaymentStatus> pollStatus(String reference) async* {
    final deadline = DateTime.now().add(ApiConfig.paymentTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final s = await status(reference);
      yield s;
      if (s == PaymentStatus.success ||
          s == PaymentStatus.failed ||
          s == PaymentStatus.cancelled ||
          s == PaymentStatus.expired) {
        return;
      }
      await Future.delayed(ApiConfig.paymentPollInterval);
    }
    yield PaymentStatus.expired;
  }
}
