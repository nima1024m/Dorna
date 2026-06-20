import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// A single settings row: leading icon · title · optional detail/trailing.
/// Rows carry a bottom hairline unless [last]. [destructive] tints icon+title
/// with the error color (e.g. Sign out).
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool last;
  final bool destructive;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.trailing,
    this.onTap,
    this.last = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = destructive ? cs.error : cs.primary;
    final titleColor = destructive ? cs.error : cs.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(
                    bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: tt.bodyLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: DornaSpacing.sm),
                Text(
                  detail!,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: DornaSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
