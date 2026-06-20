import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// "Around You" teaser. Two variants:
/// - populated: `explore` tile + place/tip + chevron (when [place] is set)
/// - prompt: `location_on` tile + "Turn on location…" with an inline link
class AroundYouTeaser extends StatelessWidget {
  final String? place;
  final String tip;
  final VoidCallback onTap;

  const AroundYouTeaser({
    super.key,
    required this.tip,
    required this.onTap,
    this.place,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPlace = place != null;
    final accent = isPlace ? cs.primary : cs.secondary;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(DornaRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DornaRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(DornaSpacing.gutter),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DornaRadii.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(DornaRadii.md),
                ),
                child: Icon(isPlace ? Icons.explore_outlined : Icons.location_on_outlined,
                    color: accent, size: 26),
              ),
              const SizedBox(width: DornaSpacing.md),
              Expanded(
                child: isPlace
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Near $place',
                              style: tt.labelLarge?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(tip,
                              style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant, fontSize: 13)),
                        ],
                      )
                    : Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                                text: 'Turn on location for tips near you. ',
                                style: tt.bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                            TextSpan(
                                text: 'Enable location',
                                style: tt.bodyMedium?.copyWith(
                                    color: cs.secondary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
              ),
              if (isPlace) ...[
                const SizedBox(width: DornaSpacing.sm),
                Icon(Icons.chevron_right, color: cs.outlineVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
