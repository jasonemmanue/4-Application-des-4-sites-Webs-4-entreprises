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

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.duration.inSeconds == 0 ? 0.0 : _remaining / widget.duration.inSeconds;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppColors.darkBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_remaining}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  )),
              const SizedBox(height: 2),
              const Text('restantes',
                  style: TextStyle(color: AppColors.darkMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
