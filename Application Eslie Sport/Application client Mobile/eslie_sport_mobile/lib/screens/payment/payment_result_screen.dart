import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/whatsapp_service.dart';

class PaymentResultScreen extends StatelessWidget {
  final String reference;
  final bool success;
  final String? message;

  const PaymentResultScreen({
    super.key,
    required this.reference,
    required this.success,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    final icon = success ? Icons.check_circle : Icons.error;
    return Scaffold(
      appBar: AppBar(
        title: Text(success ? 'Paiement reussi' : 'Paiement echoue'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
                child: Icon(icon, color: color, size: 68),
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'Merci pour votre inscription !' : 'Paiement non finalise',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (message != null)
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.darkMuted, fontSize: 14, height: 1.5),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text('Ref : $reference',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const Spacer(),
              if (success)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      WhatsAppService.instance.sendMessage(
                        message:
                            'Bonjour, je viens de finaliser un paiement. Ref : $reference',
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Envoyer la confirmation par WhatsApp'),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Retour a l\'accueil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
