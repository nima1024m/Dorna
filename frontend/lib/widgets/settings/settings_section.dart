import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// An eyebrow label above a grouped rounded card of [SettingsRow]s.
class SettingsSection extends StatelessWidget {
  final String? label;
  final List<Widget> children;

  const SettingsSection({super.key, this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: Text(
              label!.toUpperCase(),
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(DornaRadii.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DornaRadii.lg),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
