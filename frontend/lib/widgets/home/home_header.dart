import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../ui/user_avatar.dart';

/// Today-hub header: greeting + (date·weather meta OR companion subtitle) + avatar.
class HomeHeader extends StatelessWidget {
  final String title;
  final bool welcome;
  final String? subtitle;
  final String? dateLabel;
  final String? weatherTemp;
  final String? weatherLabel;
  final IconData? weatherIcon;
  final VoidCallback? onAvatarTap;

  const HomeHeader({
    super.key,
    required this.title,
    this.welcome = false,
    this.subtitle,
    this.dateLabel,
    this.weatherTemp,
    this.weatherLabel,
    this.weatherIcon,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.headlineMedium?.copyWith(
                  color: welcome ? cs.primary : cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (welcome)
                Text(
                  subtitle ?? '',
                  style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                )
              else
                _MetaRow(
                  dateLabel: dateLabel ?? '',
                  weatherTemp: weatherTemp ?? '',
                  weatherLabel: weatherLabel ?? '',
                  weatherIcon: weatherIcon ?? Icons.wb_sunny_rounded,
                ),
            ],
          ),
        ),
        const SizedBox(width: DornaSpacing.md),
        UserAvatar(size: 48, onTap: onAvatarTap),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String dateLabel;
  final String weatherTemp;
  final String weatherLabel;
  final IconData weatherIcon;
  const _MetaRow({
    required this.dateLabel,
    required this.weatherTemp,
    required this.weatherLabel,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(dateLabel,
            style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: cs.outlineVariant),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DornaRadii.full),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(weatherIcon, size: 14, color: cs.tertiary),
              const SizedBox(width: 5),
              Text('$weatherTemp · $weatherLabel',
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
