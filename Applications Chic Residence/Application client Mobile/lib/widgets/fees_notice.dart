import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/providers.dart';

/// Pastille flottante de l'accueil + pop-up explicatif, à la manière
/// d'Airbnb (« Les prix comprennent tous les frais »).
///
/// ⚠️ Le libellé n'est **pas** celui d'Airbnb : chez CHIC RESIDENCE, le prix
/// par nuit affiché sur les cartes est hors frais de service (5 %, ajoutés
/// par `POST /bookings/calculate-price`). Écrire « tous frais inclus » serait
/// faux. Le message promet donc ce qui est vrai : aucun frais caché, le
/// total s'affiche avant de payer.
class FeesNoticePill extends ConsumerWidget {
  const FeesNoticePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(feesNoticeVisibleProvider)) return const SizedBox.shrink();
    final t = context.tokens;

    // Ombre posée hors du Material pour ne pas être rognée par son clip.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: 'Aucun frais caché — en savoir plus',
        child: Material(
          color: t.pillBg,
          elevation: 0,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showFeesNoticeSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: t.isDark ? Border.all(color: t.border) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PriceTag(size: 30),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      'Aucun frais caché',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.pillText,
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

Future<void> showFeesNoticeSheet(BuildContext context, WidgetRef ref) async {
  final t = context.tokens;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.surfaceElevated,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    useSafeArea: true,
    // Navigateur racine : sinon la feuille s'ouvre dans celui du ShellRoute
    // et la barre de navigation basse reste visible, non assombrie.
    useRootNavigator: true,
    // Hauteur au contenu, sans plafond à mi-écran : le bouton ne doit
    // jamais être rogné sur un petit téléphone.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => const _FeesNoticeSheet(),
  );
  // Fermé par « J'ai compris », la croix ou un glissement : dans tous les
  // cas le message a été vu, la pastille disparaît.
  ref.read(feesNoticeVisibleProvider.notifier).state = false;
  await ref.read(sessionServiceProvider).markFeesNoticeSeen();
}

class _FeesNoticeSheet extends StatelessWidget {
  const _FeesNoticeSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Fermer',
              icon: Icon(Icons.close_rounded, color: t.textPrimary, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 8),
          const _PriceTag(size: 120)
              .animate()
              .scale(
                begin: const Offset(0.6, 0.6),
                duration: 450.ms,
                curve: Curves.easeOutBack,
              )
              .rotate(begin: -0.04, end: 0, duration: 450.ms),
          const SizedBox(height: 36),
          Text(
            'Aucune surprise : le total, frais de service inclus, '
            "s'affiche avant de payer.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("J'ai compris"),
          ),
        ],
      ),
    );
  }
}

/// Étiquette de prix dessinée — rouge de marque, carte grise décalée
/// derrière, œillet blanc. Remplace l'illustration 3D d'Airbnb.
class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: size * 1.15,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-size * 0.07, size * 0.05),
            child: Icon(
              Icons.sell_rounded,
              size: size,
              color:
                  t.isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE2E2E2),
            ),
          ),
          Icon(
            Icons.sell_rounded,
            size: size,
            color: t.brand,
            shadows: [
              Shadow(
                color: t.shadow,
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
