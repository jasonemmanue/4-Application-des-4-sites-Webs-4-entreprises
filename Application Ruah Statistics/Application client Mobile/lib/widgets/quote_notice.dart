import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';
import '../config/theme.dart';

/// Pastille flottante de l'accueil + pop-up explicatif, à la manière
/// d'Airbnb (« Les prix comprennent tous les frais »).
///
/// Ruah n'a ni paiement ni compte : le message porte sur le devis, seul
/// levier de conversion du cabinet. Contrairement aux autres apps, la
/// pastille reste affichée après lecture — c'est l'appel à l'action
/// principal, pas une simple information.
///
/// L'ancien libellé « Consultation gratuite » a été retiré : le site ne
/// promet nulle part de consultation gratuite. « Sans engagement » est
/// vrai par construction (aucun paiement, aucune inscription).
class QuoteNoticePill extends StatelessWidget {
  const QuoteNoticePill({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.16),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: 'Devis sans engagement — en savoir plus',
        child: Material(
          color: isDark ? AppColors.charcoal800 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showQuoteNoticeSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border:
                    isDark ? Border.all(color: AppColors.charcoal600) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Doc(size: 28),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      'Devis sans engagement',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.charcoal900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 400.ms)
        .slideY(begin: 0.6, end: 0, curve: Curves.easeOutCubic);
  }
}

Future<void> showQuoteNoticeSheet(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? AppColors.charcoal800 : Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    useSafeArea: true,
    // Navigateur racine : sinon la feuille s'ouvre dans celui du ShellRoute
    // et la barre de navigation basse reste visible, non assombrie.
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => _QuoteNoticeSheet(
      onStart: () {
        Navigator.of(sheetContext).pop();
        context.push(AppRoutes.quote);
      },
    ),
  );
}

class _QuoteNoticeSheet extends StatelessWidget {
  const _QuoteNoticeSheet({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : AppColors.charcoal900;
    final Color muted = isDark ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Fermer',
              icon: Icon(Icons.close_rounded, color: fg, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 8),
          const _Doc(size: 112)
              .animate()
              .scale(
                begin: const Offset(0.6, 0.6),
                duration: 450.ms,
                curve: Curves.easeOutBack,
              )
              .rotate(begin: -0.04, end: 0, duration: 450.ms),
          const SizedBox(height: 32),
          Text(
            'Décrivez votre projet en quelques étapes, '
            'un consultant vous répond sur WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sans inscription, sans paiement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 15),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            // CTA plein, inversé selon le thème — comme le bouton noir
            // d'Airbnb : charcoal sur clair, blanc sur sombre.
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : AppColors.charcoal900,
                foregroundColor: isDark ? AppColors.charcoal900 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              onPressed: onStart,
              child: const Text('Demander un devis'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Document dessiné — cyan Ruah, feuille charcoal décalée derrière.
class _Doc extends StatelessWidget {
  const _Doc({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size * 1.15,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-size * 0.08, size * 0.05),
            child: Icon(
              Icons.description_rounded,
              size: size,
              color: isDark ? AppColors.charcoal600 : const Color(0xFFE2E5EC),
            ),
          ),
          Icon(
            Icons.description_rounded,
            size: size,
            color: AppColors.brand500,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: size * 0.12,
                offset: Offset(0, size * 0.05),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
