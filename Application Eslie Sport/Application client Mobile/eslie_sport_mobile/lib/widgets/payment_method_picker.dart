import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/payment.dart';

class PaymentMethodPicker extends StatelessWidget {
  final PaymentOperator? selected;
  final ValueChanged<PaymentOperator> onChanged;

  const PaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentOperator.values.map((op) {
        final active = selected == op;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(op),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.darkBorder,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    _logo(op),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(op.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                          if (op.requiredPrefix != null)
                            Text('Numero ${op.requiredPrefix} XX XX XX XX',
                                style: const TextStyle(
                                    color: AppColors.darkMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(
                      active ? Icons.check_circle : Icons.circle_outlined,
                      color: active ? AppColors.primary : AppColors.darkMuted,
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

  Widget _logo(PaymentOperator op) {
    final (bg, letter) = switch (op) {
      PaymentOperator.wave => (const Color(0xFF1BC7E9), 'W'),
      PaymentOperator.orangeMoney => (const Color(0xFFFF7900), 'O'),
      PaymentOperator.mtnMobileMoney => (const Color(0xFFFFCC00), 'M'),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20)),
    );
  }
}
