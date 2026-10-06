import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/residence.dart';

/// Chips pilules à emoji — style Airbnb.
///
/// Trois détails qui font l'« encerclement » d'Airbnb, et qui manquaient :
///
/// 1. **Bordure dense** (`tokens.border` = #DDDDDD, pas #EBEBEB). Une bordure
///    trop pâle disparaît sur fond blanc et la chip semble flotter sans
///    contour.
/// 2. **Ombre portée légère** sur chaque chip, y compris non sélectionnée —
///    c'est elle qui détache la pilule du fond.
/// 3. **Fond distinct quand sélectionnée** (`chipBgSelected`) en plus de la
///    bordure épaissie : la sélection se lit même en un coup d'œil rapide.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ResidenceType? selected;
  final ValueChanged<ResidenceType?> onSelect;

  static const _items = <_Cat>[
    _Cat(null, 'Tous', '🌍'),
    _Cat(ResidenceType.studio, 'Studios', '🏠'),
    _Cat(ResidenceType.appartement, 'Appartements', '🏢'),
    _Cat(ResidenceType.villa, 'Villas', '🏝️'),
    _Cat(ResidenceType.duplex, 'Duplex', '🏘️'),
    _Cat(ResidenceType.chambre, 'Chambres', '🛏️'),
  ];

  @override
  Widget build(BuildContext context) {
    // 60 px pour une pilule de 40 px : compacte comme chez Airbnb, avec
    // assez de marge verticale pour que l'ombre et l'emoji ne soient pas
    // rognés (`Clip.none` sur la liste).
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _items[i];
          return _Chip(
            cat: c,
            selected: c.type == selected,
            onTap: () => onSelect(c.type),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.cat, required this.selected, required this.onTap});
  final _Cat cat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // Effet « enfoncé » quand sélectionnée : l'ombre portée disparaît et la
    // pilule descend de 1 px. Non sélectionnée, elle est en relief (ombre
    // + position haute). C'est le contraste relief/enfoncé qui rend la
    // sélection lisible d'un coup d'œil — une simple bordure épaissie ne
    // suffisait pas.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, selected ? 1 : 0, 0),
          // Compact : 14 px horizontal / 9 px vertical donne une pilule de
          // 40 px de haut, comme la référence.
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? t.chipBgSelected : t.chipBg,
            borderRadius: BorderRadius.circular(999),
            // 1.6 px non sélectionnée : c'est l'épaisseur qui donne le
            // « bien épais » demandé sans agrandir la pilule.
            border: Border.all(
              color: selected ? t.borderStrong : t.border,
              width: selected ? 2 : 1.6,
            ),
            boxShadow: selected
                ? const []
                : [
                    BoxShadow(
                      color: t.shadow,
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cat.emoji,
                style: const TextStyle(fontSize: 15, height: 1.2),
              ),
              const SizedBox(width: 7),
              Text(
                cat.label,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.2,
                  letterSpacing: -0.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cat {
  final ResidenceType? type;
  final String label;
  final String emoji;
  const _Cat(this.type, this.label, this.emoji);
}
