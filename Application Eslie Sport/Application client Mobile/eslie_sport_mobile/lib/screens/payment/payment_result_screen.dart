import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/whatsapp_service.dart';

class PaymentResultScreen extends StatelessWidget {
  final String reference;
  final bool success;
  final String? title;
  final String? message;

  const PaymentResultScreen({
    super.key,
    required this.reference,
    required this.success,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    final icon = success ? Icons.check_circle : Icons.error;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(success ? 'Confirmation' : 'Paiement non finalisé'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 68),
              ),
              const SizedBox(height: 24),
              Text(
                title ??
                    (success
                        ? 'Merci, c\'est confirmé !'
                        : 'Le paiement n\'a pas abouti'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (message != null)
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              if (reference.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Réf. $reference',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (success)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      WhatsAppService.instance.sendMessage(
                        message: reference.isEmpty
                            ? 'Bonjour, je viens de réserver une séance depuis l\'application.'
                            : 'Bonjour, je viens de finaliser un paiement. Réf. $reference',
                      );
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Écrire à la salle sur WhatsApp'),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
