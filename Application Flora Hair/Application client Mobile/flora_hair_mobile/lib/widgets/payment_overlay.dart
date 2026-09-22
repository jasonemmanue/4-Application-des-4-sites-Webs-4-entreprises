import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'payment_countdown.dart';

class PaymentOverlay extends StatelessWidget {
  const PaymentOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.totalSeconds,
    this.onCancel,
    this.onExpired,
  });

  final String title;
  final String description;
  final int totalSeconds;
  final VoidCallback? onCancel;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: FloraColors.cream)),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: FloraColors.cream.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 28),
          PaymentCountdown(
            totalSeconds: totalSeconds,
            onExpired: onExpired,
          ),
          const SizedBox(height: 28),
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Annuler',
                  style: TextStyle(color: FloraColors.cream)),
            ),
        ],
      ),
    );
  }
}
