import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/countdown_timer.dart';

class PaymentWaitScreen extends ConsumerStatefulWidget {
  final String reference;
  final PaymentOperator operator;
  final int amount;

  const PaymentWaitScreen({
    super.key,
    required this.reference,
    required this.operator,
    required this.amount,
  });

  @override
  ConsumerState<PaymentWaitScreen> createState() => _PaymentWaitScreenState();
}

class _PaymentWaitScreenState extends ConsumerState<PaymentWaitScreen> {
  StreamSubscription<PaymentStatusResponse>? _sub;
  PaymentStatus _status = PaymentStatus.pending;
  String? _message;

  @override
  void initState() {
    super.initState();
    _sub = ref
        .read(paymentServiceProvider)
        .pollStatus(widget.reference)
        .listen(_onStatus);
  }

  void _onStatus(PaymentStatusResponse s) {
    if (!mounted) return;
    setState(() {
      _status = s.status;
      _message = s.error;
    });
    if (s.status == PaymentStatus.completed ||
        s.status == PaymentStatus.failed ||
        s.status == PaymentStatus.cancelled ||
        s.status == PaymentStatus.expired ||
        s.expired) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) Navigator.of(context).pop(s.status);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    await ref.read(paymentServiceProvider).cancel(widget.reference);
    if (!mounted) return;
    Navigator.of(context).pop(PaymentStatus.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    final ussd = widget.operator != PaymentOperator.wave;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const CountdownTimer(duration: Duration(seconds: 60)),
                const SizedBox(height: 30),
                Text(
                  ussd
                      ? 'Confirmez le paiement sur votre telephone'
                      : 'Finalisation Wave en cours...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ussd
                      ? 'Vous recevrez une notification USSD ${widget.operator.label}. Composez le code PIN pour confirmer.'
                      : 'Nous verifions votre paiement Wave.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.darkMuted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    children: [
                      _row('Reference', widget.reference),
                      _row('Operateur', widget.operator.label),
                      _row('Montant', formatFcfa(widget.amount)),
                      _row('Statut', _statusLabel()),
                    ],
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!,
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 13)),
                ],
                const Spacer(),
                if (ussd)
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(paymentServiceProvider)
                          .resendPush(widget.reference);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Nouveau message USSD envoye.')),
                      );
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Renvoyer la notification USSD'),
                  ),
                TextButton(
                  onPressed: _cancel,
                  child: const Text('Annuler le paiement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(k,
                  style:
                      const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );

  String _statusLabel() => switch (_status) {
        PaymentStatus.pending => 'En attente',
        PaymentStatus.processing => 'En cours',
        PaymentStatus.completed => 'Succes',
        PaymentStatus.failed => 'Echec',
        PaymentStatus.cancelled => 'Annule',
        PaymentStatus.expired => 'Delai depasse',
      };
}
