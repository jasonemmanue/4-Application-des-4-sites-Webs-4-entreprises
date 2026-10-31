import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/payment.dart';

/// Moyens de paiement, avec leurs logos officiels.
///
/// Toujours sur fond blanc : Wave et Orange Money portent du texte noir, et
/// c'est le fond minimal demandé par les chartes des opérateurs. La liste vient
/// de `GET /payments/config` : un moyen coupé dans le back-office disparaît ici.
class OperatorGrid extends StatelessWidget {
  const OperatorGrid({
    super.key,
    required this.operators,
    required this.selected,
    required this.onSelect,
  });

  final List<PaymentOperator> operators;
  final PaymentOperator? selected;
  final ValueChanged<PaymentOperator> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: operators.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, i) {
        final op = operators[i];
        final isSelected = selected == op;
        final radius = BorderRadius.circular(FloraTheme.borderRadius);
        return Semantics(
          button: true,
          selected: isSelected,
          label: op.label,
          child: Material(
            color: Colors.white,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelect(op),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: isSelected
                        ? FloraColors.burgundy
                        : FloraColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: Image.asset(
                            op.logoAsset,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          op.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FloraColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.check_circle_rounded,
                            size: 18, color: FloraColors.burgundy),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
