import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

class InstructionCard extends StatelessWidget {
  final Widget child;
  final double width;
  final EdgeInsets? padding;

  const InstructionCard({
    super.key,
    required this.child,
    required this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 50),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DornaRadii.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
