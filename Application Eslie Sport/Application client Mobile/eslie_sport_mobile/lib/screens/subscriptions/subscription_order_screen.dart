import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/payment.dart';
import '../../models/subscription.dart';
import '../../services/api_client.dart';
import '../../services/member_profile.dart';
import '../../services/payment_service.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/checkout_section.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class SubscriptionOrderScreen extends ConsumerStatefulWidget {
  final String subscriptionId;
  const SubscriptionOrderScreen({super.key, required this.subscriptionId});

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

  // Demande deja enregistree : un second essai de paiement la reutilise au
  // lieu d'en creer un doublon au back-office.
  String? _orderId;
  String? _orderKey;

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    _payerPhone.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit(Subscription sub) async {
    if (!_formKey.currentState!.validate()) return;
    final op = _operator;
    if (op == null) {
      _snack('Choisissez un moyen de paiement.');
      return;
    }
    final ps = ref.read(paymentServiceProvider);
    if (op.needsPhone) {
      final error = ps.phoneError(op, _payerPhone.text);
      if (error != null) {
        _snack(error);
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final whatsapp = ps.normalizePhone(_whatsapp.text);
      final key = '${sub.id}|${_name.text.trim()}|$whatsapp';
      if (_orderId == null || _orderKey != key) {
        final order = await api.createSubscriptionOrder(
          subscriptionId: sub.id,
          userName: _name.text.trim(),
          userWhatsapp: whatsapp,
        );
        _orderId = order['id'].toString();
        _orderKey = key;
      }
      await ref.read(memberNameProvider.notifier).save(_name.text);

      final init = await ps.initiate(
        subscriptionOrderId: _orderId,
        operator: op,
        paymentPhone: op.needsPhone ? ps.normalizePhone(_payerPhone.text) : '',
      );
      if (!mounted) return;
      await runCheckout(
        context: context,
        ref: ref,
        init: init,
        operator: op,
        successMessage:
            'Formule « ${sub.name} » réservée. Acompte de ${formatFcfa(init.amount)} reçu, le reste se règle à la salle.',
      );
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
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
          final matches = list.where((s) => s.id == widget.subscriptionId);
          if (matches.isEmpty) {
            return const EmptyState(
              icon: Icons.card_membership,
              title: 'Formule introuvable',
              subtitle: 'Elle a peut-être été retirée du catalogue.',
            );
          }
          final sub = matches.first;
          final deposit = ref
              .read(paymentServiceProvider)
              .computeDeposit(sub.price, percent: ApiConfig.depositPercent);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatFcfa(sub.price),
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'À payer maintenant (50 %) : ${formatFcfa(deposit)}',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 13,
                      ),
                    ),
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
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nom requis';
                        if (v.trim().length < 2) return 'Nom trop court';
                        return null;
                      },
                      decoration:
                          const InputDecoration(labelText: 'Nom complet'),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _whatsapp,
                      keyboardType: TextInputType.phone,
                      maxLength: 15,
                      validator: (v) {
                        if (v == null || v.trim().length < 8) {
                          return 'Minimum 8 chiffres';
                        }
                        if (!RegExp(r'^[0-9\s\-+]+$').hasMatch(v.trim())) {
                          return 'Chiffres uniquement';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Numéro WhatsApp',
                        prefixText: '+225 ',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CheckoutSection(
                selected: _operator,
                phone: _payerPhone,
                onSelect: (op) => setState(() {
                  _operator = op;
                  if (op.needsPhone && _payerPhone.text.isEmpty) {
                    _payerPhone.text = _whatsapp.text;
                  }
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _submit(sub),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
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
