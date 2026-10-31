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
    const ops = PaymentOperator.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ops.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, i) {
        final op = ops[i];
        final isSelected = selected == op;
        return InkWell(
          onTap: () => onSelect(op),
          borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? FloraColors.lime.withValues(alpha: 0.15)
                  : FloraColors.charcoal,
              border: Border.all(
                color: isSelected ? FloraColors.lime : FloraColors.grayWarm,
                width: isSelected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(_iconFor(op), color: FloraColors.lime, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    op.label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      case PaymentOperator.card:
        return Icons.credit_card;
    }
  }
}
