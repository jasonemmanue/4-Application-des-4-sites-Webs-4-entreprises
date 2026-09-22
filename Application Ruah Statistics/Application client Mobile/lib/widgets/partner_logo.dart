import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/partner.dart';

class PartnerLogo extends StatelessWidget {
  final Partner partner;

  const PartnerLogo({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 80,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.charcoal700),
      ),
      alignment: Alignment.center,
      child: partner.logo != null
          ? CachedNetworkImage(
              imageUrl: partner.logo!,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => Text(
                partner.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )
          : Text(
              partner.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
    );
  }
}
