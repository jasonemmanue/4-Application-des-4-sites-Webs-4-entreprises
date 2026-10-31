/// Partie commune aux deux tunnels (cours et abonnement) : choix du moyen,
/// numero, puis enchainement guichet -> attente -> ecran de resultat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/payment.dart';
import '../screens/payment/payment_wait_screen.dart';
import '../services/payment_service.dart';
import 'payment_method_picker.dart';

class CheckoutSection extends ConsumerWidget {
  final PaymentOperator? selected;
  final TextEditingController phone;
  final ValueChanged<PaymentOperator> onSelect;

  const CheckoutSection({
    super.key,
    required this.selected,
    required this.phone,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(paymentConfigProvider);
    final op = selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moyen de paiement',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        PaymentMethodPicker(
          selected: op,
          availableMethods: config.valueOrNull?.operators,
          onChanged: onSelect,
        ),
        if (op != null && op.needsPhone) ...[
          const SizedBox(height: 6),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            decoration: InputDecoration(
              labelText: 'Numéro ${op.label}',
              prefixText: '+225 ',
              helperText: op.allowedPrefixes.isEmpty
                  ? 'Le numéro de votre compte ${op.label}'
                  : 'Commence par ${op.allowedPrefixes.join(', ')}',
            ),
          ),
        ],
        if (op != null && op.isCard)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous saisirez votre carte sur une page sécurisée. L\'application ne voit jamais vos données bancaires.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ouvre le guichet si besoin, attend le verdict et affiche le resultat.
Future<void> runCheckout({
  required BuildContext context,
  required WidgetRef ref,
  required PaymentInit init,
  required PaymentOperator operator,
  required String successMessage,
}) async {
  final service = ref.read(paymentServiceProvider);
  if (operator.redirectsToCheckout && init.paymentUrl.isNotEmpty) {
    await service.openCheckoutUrl(init.paymentUrl);
  }
  if (!context.mounted) return;

  final outcome = await Navigator.of(context).push<PaymentOutcome>(
    MaterialPageRoute(
      builder: (_) => PaymentWaitScreen(
        reference: init.reference,
        operator: operator,
        amount: init.amount.round(),
        expiresIn: init.expiresIn,
        paymentUrl: init.paymentUrl.isEmpty ? null : init.paymentUrl,
      ),
    ),
  );
  if (!context.mounted) return;

  final ok = outcome?.status == PaymentStatus.completed;
  final message = switch (outcome?.status) {
    PaymentStatus.completed => successMessage,
    PaymentStatus.cancelled =>
      'Vous avez annulé le paiement. Vous pouvez recommencer quand vous voulez.',
    PaymentStatus.expired =>
      'Le délai est dépassé. Si vous avez été débité, contactez la salle avec votre référence.',
    _ => 'Aucun montant n\'a été confirmé. Réessayez ou choisissez un autre moyen.',
  };
  context.pushReplacement('/payment/result', extra: {
    'reference': outcome?.reference ?? init.reference,
    'success': ok,
    'message': message,
  });
}
