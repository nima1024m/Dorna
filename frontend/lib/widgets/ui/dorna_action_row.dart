import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'dorna_card.dart';

/// A tappable [DornaCard] row: rounded leading icon-tile · title (+ optional
/// subtitle) · trailing (defaults to a chevron). The shared shape behind the
/// Practice cards, the Profile "Saved phrases" row, and similar list rows.
class DornaActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double tileSize;

  const DornaActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.tileSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return DornaCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(DornaRadii.md),
            ),
            child: Icon(icon, color: cs.primary, size: 26),
          ),
          const SizedBox(width: DornaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right, color: cs.outlineVariant),
        ],
      ),
    );
  }
}
