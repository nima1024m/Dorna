import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/onboarding/onboarding_controller.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/onboarding/onboarding_progress_dots.dart';
import '../../widgets/ui/custom_button.dart';
import 'situations_screen.dart';

/// Onboarding step 1/3 — multi-select interest chips.
class InterestsScreen extends StatelessWidget {
  static const String routeName = '/onboarding/interests';

  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = Get.isRegistered<OnboardingController>()
        ? Get.find<OnboardingController>()
        : Get.put(OnboardingController());
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DornaSpacing.screenMargin, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingProgressDots(step: 1),
              const SizedBox(height: 24),
              Text('What are you into?', style: tt.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Pick a few interests — Dorna uses them to suggest things to '
                'talk about.',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Obx(
                    () => Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        for (final it in OnboardingController.interests)
                          _InterestChip(
                            label: it.label,
                            selected: c.selectedInterests.contains(it.id),
                            onTap: () => c.toggleInterest(it.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Continue',
                onPressed: () => Get.toNamed(SituationsScreen.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? DornaColors.brandGradient : null,
          color: selected ? null : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DornaRadii.full),
          border: selected
              ? null
              : Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 16, color: cs.onPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
