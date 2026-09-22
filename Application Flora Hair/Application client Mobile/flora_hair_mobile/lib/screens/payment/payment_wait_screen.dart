import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../widgets/payment_overlay.dart';

class PaymentWaitScreen extends ConsumerStatefulWidget {
  const PaymentWaitScreen({super.key, required this.reference});
  final String reference;

  @override
  ConsumerState<PaymentWaitScreen> createState() => _PaymentWaitScreenState();
}

class _PaymentWaitScreenState extends ConsumerState<PaymentWaitScreen> {
  StreamSubscription<PaymentStatusResponse>? _sub;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    final svc = ref.read(paymentServiceProvider);
    _sub = svc.pollStatus(widget.reference).listen((status) {
      if (!mounted) return;
      switch (status.status) {
        case PaymentStatus.success:
          context.go('/payment/result?ref=${widget.reference}&ok=1');
          break;
        case PaymentStatus.failed:
        case PaymentStatus.cancelled:
        case PaymentStatus.expired:
          context.go('/payment/result?ref=${widget.reference}&ok=0');
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    try {
      await ref.read(paymentServiceProvider).cancel(widget.reference);
    } catch (_) {}
    if (!mounted) return;
    context.go('/payment/result?ref=${widget.reference}&ok=0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaymentOverlay(
        title: 'Paiement en cours',
        description:
            'Validez la notification recue sur votre telephone pour '
            'confirmer le paiement du depot.',
        totalSeconds: ApiConfig.paymentTimeoutSeconds,
        onCancel: _cancel,
        onExpired: () =>
            context.go('/payment/result?ref=${widget.reference}&ok=0'),
      ),
    );
  }
}
