import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final int? amount;
  final String? transactionId;
  final String? method;
  final String? message;

  const PaymentResultScreen({
    super.key,
    required this.success,
    this.amount,
    this.transactionId,
    this.method,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(success ? 'Paiement reussi' : 'Paiement echoue'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutes.more),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: success ? AppColors.ctaGradient : null,
                color: success ? null : Colors.red.shade700,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    success ? 'Paiement confirme !' : 'Paiement non abouti',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (amount != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$amount FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    success
                        ? 'Votre paiement a ete traite avec succes. '
                            'Un recu vous sera envoye par WhatsApp.'
                        : (message ?? 'Le paiement n\'a pas abouti. '
                            'Veuillez reessayer ou contacter le cabinet.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            if (success && transactionId != null && transactionId!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Transaction : $transactionId',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
            if (success && method != null && method!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Via $method',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Retour a l\'accueil'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!success)
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.payment),
                child: const Text('Reessayer'),
              )
            else
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.services),
                child: const Text('Explorer nos services'),
              ),
          ],
        ),
      ),
    );
  }
}
