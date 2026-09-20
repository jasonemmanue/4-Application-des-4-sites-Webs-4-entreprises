import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/payment_method_picker.dart';
import '../payment/payment_wait_screen.dart';

class SubscriptionOrderScreen extends ConsumerStatefulWidget {
  /// Le slug est ici l'`id` de la formule (les subscriptions n'ont plus de slug).
  final String slug;
  const SubscriptionOrderScreen({super.key, required this.slug});

  @override
  ConsumerState<SubscriptionOrderScreen> createState() =>
      _SubscriptionOrderScreenState();
}

class _SubscriptionOrderScreenState
    extends ConsumerState<SubscriptionOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  final _payerPhone = TextEditingController();
  PaymentOperator? _operator;
  bool _busy = false;

  Future<void> _submit(String subscriptionId, double price) async {
    if (!_formKey.currentState!.validate() || _operator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completez tous les champs.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final order = await api.createSubscriptionOrder(
        subscriptionId: subscriptionId,
        userName: _name.text.trim(),
        userWhatsapp: _whatsapp.text.trim(),
      );

      final normalized =
          ref.read(paymentServiceProvider).normalizePhone(_payerPhone.text);
      final init = await ref.read(paymentServiceProvider).initiate(
            subscriptionOrderId: order['id'].toString(),
            operator: _operator!,
            paymentPhone: normalized,
          );

      if (!mounted) return;
      if (_operator == PaymentOperator.wave && init.paymentUrl.isNotEmpty) {
        await ref
            .read(paymentServiceProvider)
            .openCheckoutUrl(init.paymentUrl);
      }
      final res = await Navigator.of(context).push<PaymentStatus?>(
        MaterialPageRoute(
          builder: (_) => PaymentWaitScreen(
            reference: init.reference,
            operator: _operator!,
            amount: init.amount.round(),
          ),
        ),
      );
      if (!mounted) return;
      final ok = res == PaymentStatus.completed;
      context.pushReplacement('/payment/result', extra: {
        'reference': init.reference,
        'success': ok,
        'message': ok
            ? 'Abonnement souscrit. Depot de ${formatFcfa(init.amount)} recu.'
            : 'Paiement non finalise.',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscriptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Souscrire')),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(subscriptionsProvider),
        ),
        data: (list) {
          final sub = list.firstWhere(
            (s) => s.id == widget.slug,
            orElse: () => list.first,
          );
          final deposit = ref
              .read(paymentServiceProvider)
              .computeDeposit(sub.price, percent: ApiConfig.depositPercent);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.name,
                        style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(formatFcfa(sub.price),
                        style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Depot 50% : ${formatFcfa(deposit)}',
                        style: const TextStyle(
                            color: AppColors.dark, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      decoration: const InputDecoration(labelText: 'Nom complet'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _whatsapp,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().length < 8) {
                          return 'Min 8 chiffres';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                          labelText: 'Numero WhatsApp',
                          prefixText: '+225 '),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Moyen de paiement',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 10),
              PaymentMethodPicker(
                selected: _operator,
                onChanged: (op) => setState(() {
                  _operator = op;
                  if (_payerPhone.text.isEmpty) _payerPhone.text = _whatsapp.text;
                }),
              ),
              if (_operator != null) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _payerPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numero ${_operator!.label}',
                    prefixText: '+225 ',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _submit(sub.id, sub.price),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.dark))
                      : const Icon(Icons.lock),
                  label: Text(
                    _busy ? 'Traitement...' : 'Payer ${formatFcfa(deposit)}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
