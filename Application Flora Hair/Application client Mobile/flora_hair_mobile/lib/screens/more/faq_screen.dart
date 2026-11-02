import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';

/// Questions fréquentes. Le backend du salon n'a pas de FAQ : les réponses
/// reprennent les règles du salon appliquées par l'API (acompte, annulation,
/// moyens de paiement, horaires).
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faq = <(String, String)>[
    (
      'Comment réserver ?',
      'Onglet « Réserver » : choisissez la prestation et votre expert·e, puis '
          'un créneau, et confirmez en réglant l\'acompte. Aucun compte n\'est '
          'nécessaire.',
    ),
    (
      'Pourquoi un acompte de 50 % ?',
      'L\'acompte confirme votre rendez-vous et réserve le créneau. Le reste '
          'se règle au salon après la prestation.',
    ),
    (
      'Quels moyens de paiement sont acceptés ?',
      'Wave, Orange Money, MTN Mobile Money et la carte bancaire (Visa, '
          'Mastercard). Le salon ne voit jamais votre code secret ni votre '
          'numéro de carte.',
    ),
    (
      'Que se passe-t-il si je ne paie pas l\'acompte ?',
      'Une demande sans acompte est annulée au bout de 30 minutes et le '
          'créneau est remis en vente. Vous pouvez payer depuis « Mes '
          'rendez-vous » tant qu\'elle est en attente.',
    ),
    (
      'Puis-je annuler mon rendez-vous ?',
      'Oui, depuis « Mes rendez-vous », tant que l\'acompte n\'est pas réglé. '
          'Une fois l\'acompte payé, contactez le salon.',
    ),
    (
      'Comment savoir si mon rendez-vous est confirmé ?',
      'Son état est affiché dans « Mes rendez-vous » et une notification '
          'arrive dans la cloche de l\'accueil dès que le salon le confirme.',
    ),
    (
      'Le prix affiché est-il définitif ?',
      'Pour une fourchette ou un tarif « à partir de », le prix final dépend '
          'de la longueur et du volume. Pour une estimation, envoyez une photo '
          'avec « Devis sur photo ».',
    ),
    (
      'Quels sont les horaires du salon ?',
      'Lundi à mercredi de 9h à 19h, jeudi et vendredi de 9h à 20h, samedi de '
          '8h à 18h. Fermé le dimanche.',
    ),
    (
      'Comment m\'inscrire à une formation ?',
      'Les tarifs et les sessions de formation se donnent par l\'infoline : '
          '${ApiConfig.salonInfoline}.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Questions fréquentes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          for (final (q, a) in _faq)
            ExpansionTile(
              title: Text(
                q,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: FloraColors.textPrimary,
                ),
              ),
              iconColor: FloraColors.burgundy,
              collapsedIconColor: FloraColors.textSecondary,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedAlignment: Alignment.centerLeft,
              children: <Widget>[
                Text(
                  a,
                  style: const TextStyle(
                    height: 1.45,
                    color: FloraColors.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
