import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/partner_logo.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(partnersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('A propos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ApiConfig.companyName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 2,
                        )),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Cabinet d'etudes et de conseil",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  "Base a Abidjan (Cote d'Ivoire) avec un bureau regional a Dakar (Senegal), "
                  "nous accompagnons entreprises, institutions et bailleurs de fonds "
                  "en Afrique francophone depuis pres de deux decennies.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _section(context, 'Notre mission',
              "Fournir a nos clients des donnees fiables, des analyses rigoureuses "
              "et des recommandations operationnelles pour eclairer leurs decisions strategiques."),
          _section(context, 'Notre vision',
              "Devenir le cabinet d'etudes de reference en Afrique francophone, "
              "reconnu pour la qualite de ses livrables et l'impact de ses recommandations."),
          _section(context, 'Nos valeurs',
              "Rigueur - Independance - Confidentialite - Ecoute - Engagement"),
          const SizedBox(height: AppSpacing.lg),
          Text('Nos bureaux',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          _office(context, 'Siege - Abidjan',
              "123 Avenue de l'Independance, Cote d'Ivoire"),
          const SizedBox(height: AppSpacing.sm),
          _office(context, 'Bureau regional - Dakar',
              "Bureau regional pour l'Afrique de l'Ouest, Senegal"),
          const SizedBox(height: AppSpacing.lg),
          Text('Nos partenaires',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          partners.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final p in items) PartnerLogo(partner: p)],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _office(BuildContext context, String title, String address) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on, color: AppColors.brand500),
        title: Text(title,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(address),
      ),
    );
  }
}
