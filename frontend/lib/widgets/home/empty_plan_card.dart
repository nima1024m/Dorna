import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../ui/custom_button.dart';

/// A centered empty-state card (icon, title, body, outlined CTA pill).
/// Reusable across tabs; used by the Today hub's "No events yet" state.
class EmptyPlanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  const EmptyPlanCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: DornaSpacing.xl, vertical: DornaSpacing.xxl),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DornaRadii.xl),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: cs.secondary.withValues(alpha: 0.7)),
          const SizedBox(height: DornaSpacing.gutter),
          Text(title, style: tt.headlineMedium?.copyWith(color: cs.onSurface)),
          const SizedBox(height: DornaSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: DornaSpacing.xl),
          CustomButton(
            onPressed: onCta,
            text: ctaLabel,
            setDefaultHeight: false,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            backgroundColor: Colors.transparent,
            showBackgroundColorAnyway: true,
            border: Border.all(color: cs.secondary, width: 2),
            borderRadius: BorderRadius.circular(DornaRadii.full),
            textColor: cs.secondary,
          ),
        ],
      ),
    );
  }
}
