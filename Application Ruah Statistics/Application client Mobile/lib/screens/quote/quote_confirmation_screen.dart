import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';

class QuoteConfirmationScreen extends StatelessWidget {
  final String reference;

  const QuoteConfirmationScreen({super.key, required this.reference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demande envoyee')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.white, size: 64),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Demande recue !',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    "Notre equipe revient vers vous sous 48 heures avec une proposition adaptee.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            if (reference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Reference: $reference',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text("Retour a l'accueil"),
            ),
            const SizedBox(height: AppSpacing.sm),
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
