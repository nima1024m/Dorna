import 'package:flutter/material.dart';

/// A row of small dots with one active index (segment position indicator).
class DotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const DotIndicator({super.key, required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == activeIndex ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == activeIndex ? cs.primary : cs.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
