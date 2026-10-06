import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Pilule « Commencez votre recherche » — style Airbnb.
///
/// Mode « tap-to-open » sur la Home (`readOnly: true` + `onTap`), ou éditable
/// quand [readOnly] vaut `false` et qu'un [controller] est fourni.
///
/// Toutes les couleurs viennent de `context.tokens` : la pilule est blanche
/// en mode clair, gris anthracite en mode sombre, et le texte suit.
class SearchBarField extends StatelessWidget {
  const SearchBarField({
    super.key,
    this.onTap,
    this.controller,
    this.readOnly = true,
    this.hint = 'Commencez votre recherche',
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: t.textPrimary,
    );

    // Deux ombres superposées : une large et très diffuse pour le halo, une
    // courte et plus dense juste sous la pilule. C'est ce doublement qui
    // donne le relief net d'Airbnb — une seule ombre paraît soit plate, soit
    // sale.
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: t.shadow,
            blurRadius: 8,
            spreadRadius: -4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Icon(Icons.search_rounded, color: t.textPrimary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              autofocus: autofocus,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              style: textStyle,
              cursorColor: t.textPrimary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: textStyle,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
