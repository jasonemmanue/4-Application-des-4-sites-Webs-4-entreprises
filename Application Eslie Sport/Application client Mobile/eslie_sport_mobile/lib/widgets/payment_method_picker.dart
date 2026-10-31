import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/payment.dart';

/// Choix du moyen de paiement, avec les logos reels des operateurs.
///
/// La liste vient de `GET /payments/config` : un moyen coupe cote serveur
/// disparait ici sans mise a jour de l'application.
class PaymentMethodPicker extends StatelessWidget {
  final PaymentOperator? selected;
  final ValueChanged<PaymentOperator> onChanged;
  final List<PaymentOperator>? availableMethods;

  const PaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.availableMethods,
  });

  @override
  Widget build(BuildContext context) {
    final methods = availableMethods ?? PaymentOperator.values;
    final mobileMoney =
        methods.where((op) => !op.isCard).toList(growable: false);
    final cards = methods.where((op) => op.isCard).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mobileMoney.isNotEmpty) ...[
          const _SectionLabel('Mobile Money'),
          const SizedBox(height: 10),
          ...mobileMoney.map(_tile),
        ],
        if (cards.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionLabel('Carte bancaire'),
          const SizedBox(height: 10),
          ...cards.map(_tile),
        ],
      ],
    );
  }

  Widget _tile(PaymentOperator op) {
    final active = selected == op;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: active,
        label: op.label,
        child: Material(
          color: active ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: () => onChanged(op),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: active ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  _PaymentLogo(op),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          op.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _hint(op),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    active ? Icons.check_circle : Icons.circle_outlined,
                    color: active ? AppColors.primary : AppColors.borderStrong,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _hint(PaymentOperator op) {
    if (op.isCard) return 'Visa, Mastercard — page sécurisée';
    if (op == PaymentOperator.wave) return 'Ouvre la page de paiement Wave';
    return 'Numéro en ${op.allowedPrefixes.join(', ')} — validation USSD';
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PaymentLogo extends StatelessWidget {
  final PaymentOperator op;
  const _PaymentLogo(this.op);

  @override
  Widget build(BuildContext context) {
    final asset = op.logoAsset;
    if (asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Image.asset(
            asset,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            semanticLabel: 'Logo ${op.label}',
          ),
        ),
      );
    }
    return Container(
      width: 72,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              PaymentOperatorX.cardLogos[0],
              semanticLabel: 'Visa',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Image.asset(
              PaymentOperatorX.cardLogos[1],
              semanticLabel: 'Mastercard',
            ),
          ),
        ],
      ),
    );
  }
}
