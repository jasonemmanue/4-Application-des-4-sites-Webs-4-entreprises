import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _items = <_MoreItem>[
    _MoreItem(icon: Icons.groups_2_outlined, label: 'Coachs', route: '/coaches'),
    _MoreItem(
        icon: Icons.sports_gymnastics_outlined,
        label: 'Equipements',
        route: '/equipment'),
    _MoreItem(icon: Icons.article_outlined, label: 'Articles', route: '/articles'),
    _MoreItem(
        icon: Icons.play_circle_outline, label: 'Videos', route: '/videos'),
    _MoreItem(
        icon: Icons.compare_arrows_outlined,
        label: 'Transformations',
        route: '/transformations'),
    _MoreItem(
        icon: Icons.reviews_outlined, label: 'Avis clients', route: '/reviews'),
    _MoreItem(icon: Icons.calculate_outlined, label: 'Calcul IMC', route: '/bmi'),
    _MoreItem(icon: Icons.mail_outline, label: 'Contact', route: '/contact'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final it = _items[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => context.push(it.route),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(it.icon, color: AppColors.primary),
                        ),
                        Text(it.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _AboutCard(),
        ],
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _MoreItem({required this.icon, required this.label, required this.route});
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ESLIE SPORT',
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(ApiConfig.slogan,
              style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 13)),
          const SizedBox(height: 12),
          _row(Icons.location_on_outlined, ApiConfig.gymLocation),
          _row(Icons.phone_outlined, ApiConfig.contactPhoneDisplay,
              onTap: () => launchUrl(Uri.parse('tel:${ApiConfig.contactPhone}'))),
          _row(Icons.chat_outlined, 'WhatsApp',
              onTap: () => launchUrl(
                  Uri.parse('https://wa.me/${ApiConfig.whatsappNumber}'))),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.darkMuted),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
