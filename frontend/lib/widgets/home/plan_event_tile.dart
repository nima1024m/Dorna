import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// A single "Today's Plan" event row: status dot · time + title · "Prep" chip.
class PlanEventTile extends StatelessWidget {
  final String time;
  final String title;
  final bool dotAccent;
  final String trailingLabel;
  final VoidCallback? onTap;

  const PlanEventTile({
    super.key,
    required this.time,
    required this.title,
    this.dotAccent = false,
    this.trailingLabel = 'Prep',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(DornaRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DornaRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(DornaSpacing.gutter),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DornaRadii.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: DornaSpacing.gutter),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotAccent ? DornaColors.accentCyan : cs.primary,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: time,
                        style: tt.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '  —  $title',
                        style: tt.labelLarge?.copyWith(color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DornaSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(DornaRadii.full),
                ),
                child: Text(
                  trailingLabel,
                  style: tt.labelLarge?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
