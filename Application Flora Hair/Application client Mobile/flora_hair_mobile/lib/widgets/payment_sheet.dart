import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/payment.dart';
import '../models/service.dart' show formatFcfa;
import '../services/api_client.dart';
import '../services/appointments.dart';
import '../services/payment_service.dart';
import 'operator_grid.dart';

/// Ouvre la page de paiement si le moyen l'exige, puis l'écran d'attente.
///
/// Wave exige le navigateur externe (`docs.wave.com/checkout`) : ouvert dans
/// une webview, son lien ne redirige pas vers l'application Wave. Orange et MTN
/// reçoivent la demande de validation directement du serveur.
Future<void> continueToPayment(
  BuildContext context,
  PaymentInit init,
  PaymentOperator operator,
) async {
  final url = init.checkoutUrl;
  if (operator.opensExternally && url != null) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
  if (!context.mounted) return;
  context.go('/payment/wait?ref=${init.reference}&op=${operator.code}');
}

/// Choisir un moyen puis payer l'acompte d'un rendez-vous déjà enregistré :
/// `reference` relance une transaction, `bookingId` en ouvre une première.
Future<void> showPaymentSheet(
  BuildContext context, {
  String? reference,
  String? bookingId,
  int? amount,
  String? initialPhone,
}) async {
  assert(reference != null || bookingId != null);
  final result = await showModalBottomSheet<(PaymentInit, PaymentOperator)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FloraColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PaymentSheet(
      reference: reference,
      bookingId: bookingId,
      amount: amount,
      initialPhone: initialPhone,
    ),
  );
  if (result == null || !context.mounted) return;
  await continueToPayment(context, result.$1, result.$2);
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({
    this.reference,
    this.bookingId,
    this.amount,
    this.initialPhone,
  });

  final String? reference;
  final String? bookingId;
  final int? amount;
  final String? initialPhone;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final _phone = TextEditingController(text: widget.initialPhone ?? '');
  PaymentOperator? _operator;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final op = _operator;
    if (op == null) {
      setState(() => _error = 'Choisissez un moyen de paiement.');
      return;
    }
    if (op.needsPhone) {
      final problem = PaymentService.validatePhone(_phone.text);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone =
        op.needsPhone ? PaymentService.toInternational(_phone.text) : null;
    final service = ref.read(paymentServiceProvider);
    final appointments = ref.read(appointmentsProvider.notifier);
    try {
      final PaymentInit init;
      if (widget.reference != null) {
        init = await service.retry(
            reference: widget.reference!, operator: op, phone: phone);
        await appointments.replacePayment(widget.reference!, init.reference);
      } else {
        init = await service.initPayment(
            bookingId: widget.bookingId!, operator: op, phone: phone);
        await appointments.attachPayment(widget.bookingId!, init.reference);
      }
      if (mounted) Navigator.of(context).pop((init, op));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException ? e.message : 'Une erreur est survenue.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(paymentConfigProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              "Payer l'acompte",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: FloraColors.textPrimary,
              ),
            ),
            if (widget.amount != null && widget.amount! > 0) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                formatFcfa(widget.amount!),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: FloraColors.burgundy,
                ),
              ),
            ],
            const SizedBox(height: 14),
            config.when(
              data: (c) => OperatorGrid(
                operators: c.operators,
                selected: _operator,
                onSelect: (op) => setState(() {
                  _operator = op;
                  _error = null;
                }),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => TextButton(
                onPressed: () => ref.invalidate(paymentConfigProvider),
                child: const Text('Réessayer de charger les moyens de paiement'),
              ),
            ),
            if (_operator?.needsPhone ?? false) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'Numéro ${_operator!.label}',
                  hintText: '07 07 07 07 07',
                  counterText: '',
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: FloraColors.danger)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _pay,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Payer maintenant'),
            ),
          ],
        ),
      ),
    );
  }
}
