import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// The shared rounded surface card used across the redesign. [soft] drops the
/// shadow (for flat tiles); [onTap] makes it tappable with an ink ripple.
class DornaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool soft;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const DornaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DornaSpacing.gutter),
    this.soft = false,
    this.onTap,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decoration = BoxDecoration(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(DornaRadii.lg),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      boxShadow: soft
          ? null
          : [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
    );
    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: decoration,
        clipBehavior: clipBehavior,
        child: child,
      );
    }
    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(DornaRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DornaRadii.lg),
        child: Ink(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
