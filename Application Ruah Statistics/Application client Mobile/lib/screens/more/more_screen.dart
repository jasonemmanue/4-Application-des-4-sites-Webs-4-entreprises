import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/whatsapp_service.dart';

const _whatsapp = WhatsAppService();

/// Ecran « Plus », refonte facon Airbnb Profile (Vi3.jpg) :
///
/// - Grand titre XL en haut a gauche
/// - Sous-titre gris explicatif
/// - CTA principal pleine largeur (gradient cyan) — remplace le « Log in or
///   sign up » d'Airbnb, oriente sur l'action de conversion Ruah : le devis
/// - Liste de sections avec icone rond outline + chevron droit
/// - Separateur puis groupe secondaire (Contact WhatsApp, Legal)
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? AppColors.charcoal900 : AppColors.lightBg;
    final Color titleFg = isDark ? Colors.white : AppColors.charcoal900;
    final Color subFg = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xl),
          children: [
            Text(
              'Plus',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: titleFg,
                height: 1.05,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Explorez le cabinet, ses experts et ses ressources.',
              style: TextStyle(
                fontSize: 15,
                color: subFg,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PrimaryCta(
              label: 'Demander un devis',
              onTap: () => context.push(AppRoutes.quote),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              isDark: isDark,
              items: [
                _MenuItem(
                  icon: Icons.groups_outlined,
                  label: 'Notre equipe',
                  onTap: () => context.push(AppRoutes.team),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'A propos du cabinet',
                  onTap: () => context.push(AppRoutes.about),
                ),
                _MenuItem(
                  icon: Icons.play_circle_outline,
                  label: 'Videos',
                  onTap: () => context.push(AppRoutes.videos),
                ),
                _MenuItem(
                  icon: Icons.rate_review_outlined,
                  label: 'Temoignages clients',
                  onTap: () => context.push(AppRoutes.testimonials),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              isDark: isDark,
              items: [
                _MenuItem(
                  icon: Icons.mail_outline,
                  label: 'Contacter le cabinet',
                  onTap: () => context.push(AppRoutes.contact),
                ),
                _MenuItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'WhatsApp direct',
                  onTap: () => _whatsapp.sendPreFilledMessage(
                    'Bonjour, je souhaite echanger avec ${ApiConfig.companyName}.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'RUAH-STATISTICS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand400,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Cabinet d\'etudes & conseil, Abidjan',
                style: TextStyle(fontSize: 12, color: subFg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final bool isDark;
  final List<_MenuItem> items;

  const _Section({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    final Color divider =
        isDark ? AppColors.charcoal700 : const Color(0xFFE5E7EB);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal800 : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 56,
                color: divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : AppColors.charcoal900;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 24, color: fg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 22,
                color: isDark ? Colors.white54 : Colors.black38),
          ],
        ),
      ),
    );
  }
}
