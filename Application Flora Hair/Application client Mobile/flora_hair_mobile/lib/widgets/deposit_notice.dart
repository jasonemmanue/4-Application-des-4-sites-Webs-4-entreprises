/// Pastille flottante de l'accueil + pop-up explicatif, à la manière
/// d'Airbnb (« Les prix comprennent tous les frais »).
///
/// Le message est celui de Flora Hair : le rendez-vous se confirme en
/// payant 50 % en ligne par Mobile Money, le reste se règle au salon — voir
/// « ACOMPTE DE 50 % PAYÉ EN LIGNE » dans le CLAUDE.md du site.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/client_profile.dart';

class DepositNoticePill extends ConsumerWidget {
  const DepositNoticePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(depositNoticeVisibleProvider)) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      // Ombre hors du Material pour ne pas être rognée par son clip.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1A1510),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: "Réservez avec 50 % d'acompte — en savoir plus",
        child: Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showDepositNoticeSheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Tag(size: 28),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      "Réservez avec 50 % d'acompte",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

Future<void> showDepositNoticeSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: Colors.black.withOpacity(0.45),
    useSafeArea: true,
    // Navigateur racine : sinon la feuille s'ouvre dans celui du ShellRoute
    // et la barre de navigation basse reste visible, non assombrie.
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => const _DepositNoticeSheet(),
  );
  // Fermé par le bouton, la croix ou un glissement : le message a été vu.
  await ref.read(depositNoticeVisibleProvider.notifier).dismiss();
}

class _DepositNoticeSheet extends StatelessWidget {
  const _DepositNoticeSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Fermer',
              icon: Icon(Icons.close_rounded, color: cs.onSurface, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 8),
          const _Tag(size: 116)
              .animate()
              .scale(
                begin: const Offset(0.6, 0.6),
                duration: 450.ms,
                curve: Curves.easeOutBack,
              )
              .rotate(begin: -0.04, end: 0, duration: 450.ms),
          const SizedBox(height: 32),
          Text(
            'Payez 50 % en ligne pour confirmer votre rendez-vous, '
            'le reste se règle au salon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Par Mobile Money, en toute sécurité.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            // CTA chocolat plein — l'équivalent du bouton noir d'Airbnb dans
            // la palette Flora.
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.onSurface,
                foregroundColor: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("J'ai compris"),
            ),
          ),
        ],
      ),
    );
  }
}

/// Étiquette de prix dessinée — or Flora, carte crème décalée derrière.
class _Tag extends StatelessWidget {
  const _Tag({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size * 1.15,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-size * 0.07, size * 0.05),
            child: Icon(Icons.sell_rounded, size: size, color: cs.outline),
          ),
          Icon(
            Icons.sell_rounded,
            size: size,
            color: cs.primary,
            shadows: [
              Shadow(
                color: const Color(0x401A1510),
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
