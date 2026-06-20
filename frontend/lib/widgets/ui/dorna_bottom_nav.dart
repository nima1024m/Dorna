import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

class DornaNavItem {
  final IconData icon;
  final String label;
  const DornaNavItem({required this.icon, required this.label});
}

/// Glass 3-tab bottom navigation (Today / Practice / Profile per DESIGN.md).
/// The active tab shows its icon inside a `primaryContainer` pill. Meant to sit
/// over an `extendBody: true` Scaffold so the blur reveals content behind it.
class DornaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DornaNavItem> items;

  const DornaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(DornaRadii.xl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DornaSpacing.sm, vertical: DornaSpacing.sm),
              child: Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    _NavTab(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final DornaNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DornaRadii.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? cs.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(DornaRadii.full),
                ),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
