import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/theme.dart';
import '../models/payment.dart';

/// Logo officiel d'un moyen de paiement, posé sur une tuile **blanche** dans les
/// deux thèmes : le logo Orange Money est noir sur fond transparent et
/// disparaîtrait sur un fond sombre. `contain` : deux logos sont des blocs
/// horizontaux, deux sont carrés, un format imposé les écraserait.
class PaymentLogoTile extends StatelessWidget {
  const PaymentLogoTile({
    super.key,
    required this.channel,
    this.height = 56,
  });

  final PaymentChannel channel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final asset = channel.logoAsset;
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.isDark ? Colors.transparent : t.border),
      ),
      child: asset.endsWith('.svg')
          ? SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              semanticsLabel: channel.label,
            )
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              semanticLabel: channel.label,
            ),
    );
  }
}

/// Carte de sélection : tuile du logo, nom dessous, cadre coloré si choisie.
class PaymentChannelCard extends StatelessWidget {
  const PaymentChannelCard({
    super.key,
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final PaymentChannel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: channel.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? t.brand.withValues(alpha: 0.08)
                : t.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? t.brand : t.border,
              width: selected ? 2 : 1.4,
            ),
          ),
          child: Column(
            children: [
              PaymentLogoTile(channel: channel),
              const SizedBox(height: 8),
              Text(
                channel.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
