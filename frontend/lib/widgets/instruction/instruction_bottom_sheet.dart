import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class InstructionBottomSheetContent extends StatelessWidget {
  const InstructionBottomSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: 15.sp,
          height: 1.5,
          color: cs.onSurface,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 14.sp,
          height: 1.35,
          color: cs.onSurfaceVariant,
        );

    return Container(
      padding: const EdgeInsets.only(bottom: 32, top: 20, left: 48, right: 48),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 70,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Text('Why Full Access?', style: titleStyle),
                Positioned(
                  left: -24,
                  child: Image.asset(
                    'assets/images/ic_key.png',
                    width: 18,
                    height: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enabling Full Access lets us personalize your keyboard, sync settings, update suggestions, and enable online features.',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Text(
                  'We never collect your typed text or passwords — your privacy is 100% safe.',
                  style: titleStyle?.copyWith(fontSize: 13.sp),
                ),
                Positioned(
                  left: -24,
                  child: Image.asset(
                    'assets/images/ic_finger.png',
                    width: 18,
                    height: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

