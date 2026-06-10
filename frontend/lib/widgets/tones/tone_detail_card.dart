import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';

import '../ui/app_colors.dart';

class ToneDetailsCard extends StatelessWidget {
  final List<String> useCases;
  final List<String> traits;
  final String beforeExample;
  final String afterExample;
  final String afterLabel;

  const ToneDetailsCard({
    Key? key,
    required this.useCases,
    required this.traits,
    required this.beforeExample,
    required this.afterExample,
    required this.afterLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16, top: 12,left: 20,right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Use case:'),
          const SizedBox(height: 4),
          ...useCases
              .map((c) => _Bullet(
                    text: c,
                  ))
              .toList(),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Tone Traits:'),
          const SizedBox(height: 4),
          ...traits.map((t) => _Bullet(text: t)).toList(),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Example:'),
          const SizedBox(height: 4),
          _Bullet(
            prefix: 'Before (Neutral):',
            text: '\n"$beforeExample"',
            isItalic: true,
          ),
          _Bullet(
            prefix: '$afterLabel:',
            text: '\n"$afterExample"',
            prefixColor: AppColors.textMain(),
            isItalic: true,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            color: AppColors.textMain(),
          ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final String? prefix;
  final Color? prefixColor;
  final bool isItalic;

  const _Bullet({
    Key? key,
    required this.text,
    this.prefix,
    this.prefixColor,
    this.isItalic = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color secondary =
        isDarkMode ? Colors.white.withOpacity(0.5) : AppColors.greySubtext();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '•',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 9.sp,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  if (prefix != null)
                    TextSpan(
                      text: '${prefix!} ',
                      style: prefixColor != null
                          ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: prefixColor ?? secondary,
                                fontSize: 13.sp,
                              )
                          : Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: prefixColor ?? secondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  TextSpan(
                    text: text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: secondary,
                      fontSize: 13.sp,
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
