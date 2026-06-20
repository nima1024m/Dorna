import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// A static row of rounded vertical bars — the signature audio-wave motif.
/// Used large on the brief hero card and tiny in the mini-player.
class BriefWaveform extends StatelessWidget {
  final Color color;
  final double height;
  final double barWidth;
  final double gap;

  const BriefWaveform({
    super.key,
    required this.color,
    this.height = 56,
    this.barWidth = 4,
    this.gap = 4,
  });

  // A fixed, pleasant-looking set of relative bar heights (0..1).
  static const List<double> _pattern = [
    0.35, 0.6, 0.45, 0.85, 0.55, 1.0, 0.7, 0.4, 0.9, 0.5,
    0.75, 0.3, 0.65, 0.5, 0.8, 0.4,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final h in _pattern)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gap / 2),
              child: Container(
                width: barWidth,
                height: (height * 0.25) + (height * 0.75) * h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(DornaRadii.full),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
