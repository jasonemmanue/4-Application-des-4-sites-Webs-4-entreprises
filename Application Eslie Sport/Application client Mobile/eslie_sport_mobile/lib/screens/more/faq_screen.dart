import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';

/// Questions frequentes.
///
/// L'API Eslie n'expose pas de FAQ (Chic Residence lit `GET /faq`) : les
/// reponses sont ecrites ici, et les horaires viennent des parametres du
/// back-office pour rester a jour.
class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = ref.watch(publicSettingsProvider).valueOrNull?.openingHours ??
        'Lundi - Dimanche : 07h - 20h';
    final items = <(String, String)>[
      (
        'Comment réserver une séance ?',
        'Ouvrez le Planning, choisissez un jour puis un cours et touchez '
            '« Réserver ma place ». Indiquez votre nom, votre WhatsApp, la date '
            'et votre formule, puis réglez l\'acompte.',
      ),
      (
        'Pourquoi payer 50 % en ligne ?',
        'L\'acompte de 50 % retient votre place. Le reste se règle à la salle, '
            'le jour de la séance.',
      ),
      (
        'Quels moyens de paiement sont acceptés ?',
        'Wave, Orange Money, MTN Mobile Money et carte bancaire Visa ou '
            'Mastercard. La carte se saisit sur une page sécurisée : '
            'l\'application ne voit jamais vos données bancaires.',
      ),
      (
        'Je n\'ai pas reçu la demande Orange Money ou MTN.',
        'Vérifiez que le numéro saisi est bien celui de votre compte '
            'Mobile Money, puis touchez « Renvoyer la demande » sur l\'écran '
            'd\'attente.',
      ),
      (
        'J\'ai payé mais l\'application n\'a pas confirmé.',
        'Touchez « J\'ai payé, vérifier maintenant ». Si rien ne change, '
            'écrivez-nous sur WhatsApp avec la référence du paiement : un '
            'règlement reçu reste toujours pris en compte.',
      ),
      (
        'Le cours est complet, que se passe-t-il ?',
        'Vous êtes placé sur liste d\'attente et la salle vous contacte dès '
            'qu\'une place se libère.',
      ),
      ('Quels sont les horaires de la salle ?', hours),
      (
        'Faut-il créer un compte ?',
        'Non. Votre nom et votre numéro WhatsApp suffisent ; la confirmation '
            'arrive sur WhatsApp.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Questions fréquentes')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.textSecondary,
              title: Text(
                items[i].$1,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items[i].$2,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
