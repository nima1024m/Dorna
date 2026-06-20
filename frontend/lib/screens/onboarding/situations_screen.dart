import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/onboarding/onboarding_controller.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/onboarding/onboarding_progress_dots.dart';
import '../../widgets/ui/custom_button.dart';
import 'permissions_screen.dart';

/// Onboarding step 2/3 — multi-select everyday-situation cards.
class SituationsScreen extends StatelessWidget {
  static const String routeName = '/onboarding/situations';

  const SituationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = Get.find<OnboardingController>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DornaSpacing.screenMargin, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  const OnboardingProgressDots(step: 2),
                ],
              ),
              const SizedBox(height: 16),
              Text('What do you want to talk about?', style: tt.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Choose the everyday situations you care about most.',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Obx(
                    () => Column(
                      children: [
                        for (final s in OnboardingController.situations)
                          _SituationCard(
                            situation: s,
                            selected: c.selectedSituations.contains(s.id),
                            onTap: () => c.toggleSituation(s.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Continue',
                onPressed: () => Get.toNamed(PermissionsScreen.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SituationCard extends StatelessWidget {
  final OnboardingSituation situation;
  final bool selected;
  final VoidCallback onTap;

  const _SituationCard({
    required this.situation,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DornaRadii.lg),
          border: Border.all(
            color: selected ? DornaColors.accentCyan : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(situation.icon,
                  size: 22, color: selected ? cs.onPrimary : cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(situation.label,
                      style: tt.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(situation.example,
                      style: tt.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: DornaColors.accentCyan),
          ],
        ),
      ),
    );
  }
}
