import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../config/theme.dart';

class LoadingState extends StatelessWidget {
  final int itemCount;
  final double height;

  const LoadingState({super.key, this.itemCount = 4, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.charcoal800 : const Color(0xFFE5E7EB),
      highlightColor:
          isDark ? AppColors.charcoal700 : const Color(0xFFF3F4F6),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal800 : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}
