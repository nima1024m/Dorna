import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Onboarding step indicator: a row of dots with the active one elongated/filled,
/// followed by an "x of N" label (per the design's "1 of 3").
class OnboardingProgressDots extends StatelessWidget {
  final int step; // 1-based
  final int total;

  const OnboardingProgressDots({super.key, required this.step, this.total = 3});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= total; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == step ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == step ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DornaRadii.full),
            ),
          ),
          if (i < total) const SizedBox(width: 6),
        ],
        const SizedBox(width: 12),
        Text(
          '$step of $total',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: cs.outlineVariant),
        ),
      ],
    );
  }
}
