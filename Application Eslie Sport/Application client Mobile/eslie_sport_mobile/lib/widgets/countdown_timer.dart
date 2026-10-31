import 'dart:async';
import 'package:flutter/material.dart';

import '../config/theme.dart';

class CountdownTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onFinish;
  const CountdownTimer({super.key, required this.duration, this.onFinish});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
        widget.onFinish?.call();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _label {
    final minutes = _remaining ~/ 60;
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inSeconds == 0
        ? 0.0
        : _remaining / widget.duration.inSeconds;
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'restantes',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
