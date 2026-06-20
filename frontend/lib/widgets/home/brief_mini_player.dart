import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'brief_waveform.dart';

/// A glass mini audio-player bar that docks just above the bottom nav once a
/// brief has started. Mirrors the [DornaBottomNav] glass recipe.
class BriefMiniPlayer extends StatelessWidget {
  final bool playing;
  final String label;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final VoidCallback? onTap;

  const BriefMiniPlayer({
    super.key,
    required this.playing,
    required this.onToggle,
    required this.onClose,
    this.label = 'MORNING BRIEF',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: DornaSpacing.gutter, vertical: 10),
                child: Row(
                  children: [
                    _PlayTile(playing: playing, onTap: onToggle),
                    const SizedBox(width: DornaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: tt.labelLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          BriefWaveform(
                            color: cs.primary.withValues(alpha: 0.5),
                            height: 12,
                            barWidth: 3,
                            gap: 3,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayTile extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  const _PlayTile({required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DornaRadii.md),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: DornaColors.brandGradient,
            borderRadius: BorderRadius.circular(DornaRadii.md),
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
