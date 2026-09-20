import 'package:flutter/material.dart';

import '../config/theme.dart';

class LoadingState extends StatelessWidget {
  final String? message;
  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!,
                style: TextStyle(color: AppColors.darkMuted, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
