import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'brief_waveform.dart';

/// The signature blue→cyan "daily brief" hero card with a play button.
/// Foreground is literal white because it sits on the fixed brand gradient.
class BriefHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String durationLabel;
  final IconData? durationIcon;
  final bool playOnLeft;
  final VoidCallback onPlay;

  const BriefHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.onPlay,
    this.durationIcon,
    this.playOnLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DornaRadii.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: DornaColors.brandGradient,
          boxShadow: [
            BoxShadow(
              color: DornaColors.primary.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Faint translucent circle bleeding off the bottom-right corner.
            Positioned(
              right: -40,
              bottom: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DornaSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: tt.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _DurationPill(label: durationLabel, icon: durationIcon),
                    ],
                  ),
                  const SizedBox(height: DornaSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text(
                      subtitle,
                      style: tt.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: DornaSpacing.xl),
                  BriefWaveform(color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(height: DornaSpacing.gutter),
                  Row(
                    children: [
                      if (!playOnLeft) const Spacer(),
                      _PlayButton(onTap: onPlay, iconColor: cs.primary),
                      if (playOnLeft) const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _DurationPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DornaRadii.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DornaRadii.full),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 12,
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

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color iconColor;
  const _PlayButton({required this.onTap, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.play_arrow_rounded, size: 34, color: iconColor),
          ),
        ),
      ),
    );
  }
}
