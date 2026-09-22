import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final num end;
  final Duration duration;
  final String? suffix;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.end,
    this.duration = const Duration(milliseconds: 1400),
    this.suffix,
    this.style,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final num value = widget.end * _animation.value;
        final String text = value >= 1000
            ? value.toInt().toString()
            : value.toStringAsFixed(0);
        return Text(
          '$text${widget.suffix ?? ''}',
          style: widget.style ??
              Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
        );
      },
    );
  }
}
