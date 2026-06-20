import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Renders transcript text with [highlight] shown as an inline cyan phrase chip.
class HighlightedTranscript extends StatelessWidget {
  final String text;
  final String highlight;

  const HighlightedTranscript({
    super.key,
    required this.text,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final base = tt.bodyLarge?.copyWith(color: cs.onSurface, height: 1.65);

    final idx = text.indexOf(highlight);
    if (idx < 0) {
      return Text(text, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, idx)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: DornaColors.accentCyan.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                highlight,
                style: base?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          TextSpan(text: text.substring(idx + highlight.length)),
        ],
      ),
    );
  }
}
