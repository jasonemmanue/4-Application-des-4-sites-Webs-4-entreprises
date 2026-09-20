import 'package:flutter/material.dart';

import '../config/theme.dart';

class CapacityBadge extends StatelessWidget {
  final int available;
  final int capacity;
  final bool compact;

  const CapacityBadge({
    super.key,
    required this.available,
    required this.capacity,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = capacity == 0 ? 0 : available / capacity;
    Color color;
    String label;

    if (available <= 0) {
      color = AppColors.error;
      label = 'Complet';
    } else if (ratio <= 0.25) {
      color = AppColors.warning;
      label = 'Presque complet';
    } else {
      color = AppColors.success;
      label = 'Places disponibles';
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            compact ? '$available/$capacity' : '$label · $available/$capacity',
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
