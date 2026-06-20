import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/onboarding/onboarding_controller.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/onboarding/onboarding_progress_dots.dart';
import '../../widgets/ui/custom_button.dart';
import 'building_brief_screen.dart';

/// Onboarding step 3/3 — calendar + location permission cards.
class PermissionsScreen extends StatelessWidget {
  static const String routeName = '/onboarding/permissions';

  const PermissionsScreen({super.key});

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
                  const OnboardingProgressDots(step: 3),
                ],
              ),
              const SizedBox(height: 16),
              Text('Let Dorna learn your day', style: tt.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Connect your calendar and location so Dorna can prepare you for '
                "real conversations — like before a 5 PM networking event, or "
                "when you're at a cafe.",
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Obx(
                () => _PermissionCard(
                  icon: Icons.calendar_today,
                  title: 'Connect calendar',
                  description: 'See your events and prep you before each one',
                  actionLabel: 'Connect',
                  done: c.calendarConnected.value,
                  onAction: () => c.calendarConnected.toggle(),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _PermissionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Enable location',
                  description: 'Get conversation tips for places around you',
                  actionLabel: 'Enable',
                  done: c.locationEnabled.value,
                  onAction: () => c.locationEnabled.toggle(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Private to you. Change anytime.',
                        style: tt.labelLarge
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Finish setup',
                onPressed: () => Get.toNamed(BuildingBriefScreen.routeName),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Get.toNamed(BuildingBriefScreen.routeName),
                child: Text('Maybe later',
                    style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final bool done;
  final VoidCallback onAction;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.done,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DornaRadii.lg),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: tt.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    done
                        ? Icon(Icons.check_circle,
                            size: 20, color: DornaColors.success)
                        : GestureDetector(
                            onTap: onAction,
                            child: Text(actionLabel,
                                style: tt.labelLarge?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
