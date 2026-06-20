import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

enum DornaPillVariant { tonal, outlined }

/// A read-only rounded label chip with an optional leading dot or icon.
/// `tonal` = filled surface (weak-area / streak pills); `outlined` = bordered
/// (interest chips).
class DornaPill extends StatelessWidget {
  final String label;
  final DornaPillVariant variant;
  final bool leadingDot;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;

  const DornaPill({
    super.key,
    required this.label,
    this.variant = DornaPillVariant.tonal,
    this.leadingDot = false,
    this.icon,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final outlined = variant == DornaPillVariant.outlined;
    final bg = backgroundColor ??
        (outlined ? cs.surfaceContainerLowest : cs.surfaceContainer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DornaRadii.full),
        border: outlined
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.8))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? cs.primary),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: tt.bodyMedium?.copyWith(
              color: textColor ?? cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
