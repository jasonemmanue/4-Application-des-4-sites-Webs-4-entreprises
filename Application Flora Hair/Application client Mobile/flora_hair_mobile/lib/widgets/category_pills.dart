import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Rangée horizontale de pastilles catégorie — motif emprunté au grand
/// catalogue mobile Airbnb : icône + libellé, bordure fine, la pastille
/// active gagne une bordure noire pleine et un fond blanc pur.
///
/// L'action est confiée au parent : `onChanged(index)` reçoit la position
/// sélectionnée. Les pastilles se scrollent horizontalement, jamais
/// tronquées.
class CategoryPills extends StatelessWidget {
  const CategoryPills({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<CategoryPillItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final active = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: FloraColors.surface,
                borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
                border: Border.all(
                  color: active
                      ? FloraColors.borderStrong
                      : FloraColors.border,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(items[i].icon,
                      size: 20,
                      color: active
                          ? FloraColors.textPrimary
                          : FloraColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? FloraColors.textPrimary
                          : FloraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryPillItem {
  const CategoryPillItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
