import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/whatsapp_service.dart';
import '../booking/booking_state.dart';

class PaymentResultScreen extends ConsumerWidget {
  const PaymentResultScreen({
    super.key,
    required this.reference,
    required this.success,
  });

  final String reference;
  final bool success;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.read(bookingDraftProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? FloraColors.lime : Colors.redAccent,
                size: 88,
              ),
              const SizedBox(height: 20),
              Text(
                success ? 'Reservation confirmee !' : 'Paiement non abouti',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                success
                    ? 'Nous vous attendons avec plaisir. Une confirmation '
                        'WhatsApp vous a ete envoyee.'
                    : 'Le paiement n\'a pas abouti. Vous pouvez reessayer '
                        'avec un autre operateur.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: FloraColors.textMuted),
              ),
              const SizedBox(height: 12),
              Text(
                'Reference : $reference',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: FloraColors.textMuted),
              ),
              const SizedBox(height: 32),
              if (success && draft.service != null && draft.teamMember != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    final svc = ref.read(whatsappServiceProvider);
                    await svc.openChat(
                      message: 'Bonjour Flora Hair, je viens de reserver via '
                          'l\'application. Reference : $reference.',
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Confirmer sur WhatsApp'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  ref.read(bookingDraftProvider.notifier).reset();
                  ref.read(bookingStepProvider.notifier).state = 0;
                  context.go('/home');
                },
                child: const Text('Retour a l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
