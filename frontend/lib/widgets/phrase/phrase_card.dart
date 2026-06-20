import 'package:flutter/material.dart';

import '../../models/phrase_model.dart';
import '../../theme/app_tokens.dart';
import '../ui/dorna_card.dart';

/// A library phrase card: text + IPA, Persian gloss, when-to-use, example, and
/// a bookmark toggle.
class PhraseCard extends StatelessWidget {
  final Phrase phrase;
  final VoidCallback onToggleSave;

  const PhraseCard({
    super.key,
    required this.phrase,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return DornaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(phrase.text,
                        style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface, fontWeight: FontWeight.w700)),
                    if (phrase.ipa != null && phrase.ipa!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(phrase.ipa!,
                          style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onToggleSave,
                icon: Icon(
                  phrase.saved ? Icons.bookmark : Icons.bookmark_border,
                  color: phrase.saved ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (phrase.translation != null && phrase.translation!.isNotEmpty) ...[
            const SizedBox(height: DornaSpacing.sm),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(phrase.translation!,
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.6)),
            ),
          ],
          if (phrase.whenToUse != null && phrase.whenToUse!.isNotEmpty) ...[
            const SizedBox(height: DornaSpacing.md),
            _Labelled(label: 'When to use', value: phrase.whenToUse!),
          ],
          if (phrase.example != null && phrase.example!.isNotEmpty) ...[
            const SizedBox(height: DornaSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(DornaRadii.md),
              ),
              child: Text('“${phrase.example!}”',
                  style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface, fontStyle: FontStyle.italic)),
            ),
          ],
          if (phrase.category != null && phrase.category!.isNotEmpty) ...[
            const SizedBox(height: DornaSpacing.md),
            Text(phrase.category!.replaceAll('_', ' ').toUpperCase(),
                style: tt.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  final String label;
  final String value;
  const _Labelled({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: tt.labelLarge?.copyWith(
                color: cs.primary,
                fontSize: 10.5,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
      ],
    );
  }
}
