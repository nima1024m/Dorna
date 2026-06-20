import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// A selectable segment chip (icon + label) for the brief player.
class BriefSegmentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const BriefSegmentChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(DornaRadii.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DornaRadii.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DornaRadii.full),
            border: selected
                ? null
                : Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: selected ? cs.onPrimary : cs.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: tt.labelLarge?.copyWith(
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
