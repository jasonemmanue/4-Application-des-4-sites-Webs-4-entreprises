import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/payment.dart';

class OperatorGrid extends StatelessWidget {
  const OperatorGrid({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final PaymentOperator? selected;
  final ValueChanged<PaymentOperator> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PaymentOperator.values.map((op) {
        final isSelected = selected == op;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onSelect(op),
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FloraColors.lime.withValues(alpha: 0.15)
                      : FloraColors.charcoal,
                  border: Border.all(
                    color: isSelected
                        ? FloraColors.lime
                        : FloraColors.grayWarm,
                    width: isSelected ? 1.6 : 1,
                  ),
                  borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      _iconFor(op),
                      color: FloraColors.lime,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      op.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(PaymentOperator op) {
    switch (op) {
      case PaymentOperator.wave:
        return Icons.waves;
      case PaymentOperator.orangeMoney:
        return Icons.phone_iphone;
      case PaymentOperator.mtnMoney:
        return Icons.smartphone;
    }
  }
}
