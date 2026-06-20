import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Audio-wave visualiser that animates while [playing] and freezes when paused.
/// One bar is tinted with [accentColor] (the signature cyan glow).
class AnimatedWaveform extends StatefulWidget {
  final bool playing;
  final Color color;
  final Color accentColor;
  final int barCount;
  final double height;
  final int seed;

  const AnimatedWaveform({
    super.key,
    required this.playing,
    required this.color,
    required this.accentColor,
    this.barCount = 28,
    this.height = 96,
    this.seed = 0,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.playing && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentBar = (widget.barCount * 0.4).round();
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.barCount; i++)
                _bar(i, accentBar),
            ],
          );
        },
      ),
    );
  }

  Widget _bar(int i, int accentBar) {
    // Deterministic base height per bar, modulated by the animation phase.
    final base = 0.3 + 0.7 * ((math.sin((i + widget.seed) * 1.7) + 1) / 2);
    final wobble = widget.playing
        ? 0.5 * (math.sin((_c.value * 2 * math.pi) + i * 0.6).abs())
        : 0.0;
    final h = (widget.height * 0.18) +
        (widget.height * 0.7) * (base * (0.6 + wobble)).clamp(0.0, 1.0);
    final isAccent = i == accentBar;
    return Container(
      width: 4,
      height: h,
      decoration: BoxDecoration(
        color: isAccent ? widget.accentColor : widget.color,
        borderRadius: BorderRadius.circular(DornaRadii.full),
      ),
    );
  }
}
