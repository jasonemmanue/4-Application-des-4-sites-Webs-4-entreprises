import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class PaymentCountdown extends StatefulWidget {
  const PaymentCountdown({
    super.key,
    required this.totalSeconds,
    this.onExpired,
  });

  final int totalSeconds;
  final VoidCallback? onExpired;

  @override
  State<PaymentCountdown> createState() => _PaymentCountdownState();
}

class _PaymentCountdownState extends State<PaymentCountdown> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        widget.onExpired?.call();
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
    final progress = (_remaining / widget.totalSeconds).clamp(0.0, 1.0);
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return Column(
      children: <Widget>[
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: FloraColors.darkLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(FloraColors.lime),
                ),
              ),
              Text(
                '$minutes:$seconds',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
