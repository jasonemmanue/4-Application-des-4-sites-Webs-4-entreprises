import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Placeholders pour les ecrans admin dont l'UI reprend celle du back-office
/// Next.js (residences, bookings, payments, reviews, settings).
/// A implementer en consommant les endpoints existants.

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.construction_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
}

class ResidencesScreen extends StatelessWidget {
  const ResidencesScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        title: 'Residences',
        description:
            'Liste, creation multi-etapes et edition. Consomme /residences (CRUD).',
      );
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        title: 'Reservations',
        description:
            'Liste filtrable, changement de statut, export Excel. Consomme /bookings.',
      );
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        title: 'Paiements',
        description:
            'Journal de tous les paiements et tentatives. Consomme /payments.',
      );
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        title: 'Avis',
        description:
            'Moderation des avis clients (approuver / rejeter). Consomme /reviews.',
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        title: 'Parametres',
        description:
            'Infos entreprise, conditions, reseaux sociaux. Consomme /settings.',
      );
}
