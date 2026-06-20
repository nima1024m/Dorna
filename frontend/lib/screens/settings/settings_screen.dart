import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/settings/settings_controller.dart';
import '../../controllers/settings/settings_hub_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/auth/sign_out_dialog.dart';
import '../../widgets/settings/settings_row.dart';
import '../../widgets/settings/settings_section.dart';
import '../../widgets/ui/back_header.dart';
import '../../widgets/ui/toast.dart';
import '../../widgets/ui/user_avatar.dart';
import '../auth/profile_screen.dart';
import '../instruction/instruction_first_screen.dart';
import '../onboarding/interests_screen.dart';
import 'terms_and_privacy_screen.dart';

/// The redesigned Settings hub (reached from the Profile tab's gear).
class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  Widget _toggle(BuildContext context, bool value, ValueChanged<bool> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: cs.primary,
      activeThumbColor: cs.onPrimary,
      inactiveTrackColor: cs.surfaceContainerHighest,
      inactiveThumbColor: cs.outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hub = Get.isRegistered<SettingsHubController>()
        ? Get.find<SettingsHubController>()
        : Get.put(SettingsHubController());
    final settings = Get.find<SettingsController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile quick card
                    GestureDetector(
                      onTap: () => Get.toNamed(ProfileScreen.routeName),
                      child: Container(
                        padding: const EdgeInsets.all(DornaSpacing.gutter),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(DornaRadii.lg),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const UserAvatar(size: 52),
                            const SizedBox(width: DornaSpacing.gutter),
                            Expanded(
                              child: Obx(() {
                                final u = auth.getUserDetails;
                                final name = (u.fullName?.trim().isNotEmpty ??
                                        false)
                                    ? u.fullName!.trim()
                                    : 'Your account';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: tt.bodyLarge?.copyWith(
                                            color: cs.onSurface,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(u.email?.toString() ?? '',
                                        style: tt.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                  ],
                                );
                              }),
                            ),
                            Icon(Icons.chevron_right, color: cs.outlineVariant),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Your day
                    Obx(() => SettingsSection(
                          label: 'Your day',
                          children: [
                            SettingsRow(
                              icon: Icons.calendar_today_outlined,
                              title: 'Calendar',
                              detail: hub.calendarConnected.value
                                  ? 'Connected'
                                  : 'Off',
                              trailing: _toggle(context,
                                  hub.calendarConnected.value, hub.toggleCalendar),
                            ),
                            SettingsRow(
                              icon: Icons.location_on_outlined,
                              title: 'Location',
                              detail: hub.locationOn.value ? 'On' : 'Off',
                              trailing: _toggle(context, hub.locationOn.value,
                                  hub.toggleLocation),
                            ),
                            SettingsRow(
                              icon: Icons.schedule,
                              title: 'Daily brief time',
                              detail: hub.dailyBriefTime.value,
                              trailing:
                                  Icon(Icons.chevron_right, color: cs.outlineVariant),
                              last: true,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      const TimeOfDay(hour: 7, minute: 30),
                                );
                                if (picked != null && context.mounted) {
                                  hub.dailyBriefTime.value =
                                      picked.format(context);
                                }
                              },
                            ),
                          ],
                        )),
                    const SizedBox(height: 22),

                    // Explanations (absorbs Languages screen)
                    Obx(() => SettingsSection(
                          label: 'Explanations',
                          children: [
                            SettingsRow(
                              icon: Icons.translate,
                              title: 'Your language',
                              detail: hub.nativeLangLabel,
                              trailing: Icon(Icons.unfold_more,
                                  color: cs.onSurfaceVariant),
                              onTap: hub.toggleNativeLang,
                            ),
                            SettingsRow(
                              icon: Icons.lightbulb_outline,
                              title: 'Simple English tips',
                              trailing: _toggle(context,
                                  hub.simpleEnglishTips.value, hub.toggleSimpleTips),
                              last: true,
                            ),
                          ],
                        )),
                    const SizedBox(height: 22),

                    // Keyboard
                    SettingsSection(
                      label: 'Keyboard',
                      children: [
                        SettingsRow(
                          icon: Icons.keyboard_alt_outlined,
                          title: 'Dorna keyboard',
                          detail: 'Set up',
                          trailing:
                              Icon(Icons.chevron_right, color: cs.outlineVariant),
                          last: true,
                          onTap: () =>
                              Get.toNamed(InstructionFirstScreen.routeName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Appearance (real, working)
                    Obx(() => SettingsSection(
                          label: 'Appearance',
                          children: [
                            SettingsRow(
                              icon: Icons.dark_mode_outlined,
                              title: 'Dark mode',
                              trailing: _toggle(context, settings.isDarkTheme.value,
                                  settings.setDarkTheme),
                              last: true,
                            ),
                          ],
                        )),
                    const SizedBox(height: 22),

                    // Plan
                    SettingsSection(
                      label: 'Plan',
                      children: [
                        SettingsRow(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Free plan',
                          trailing: GestureDetector(
                            onTap: () =>
                                showCustomToast('Upgrade is coming soon', context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius:
                                    BorderRadius.circular(DornaRadii.full),
                              ),
                              child: Text('Upgrade',
                                  style: tt.labelLarge?.copyWith(
                                      color: cs.onSecondaryContainer,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          last: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Account
                    SettingsSection(
                      label: 'Account',
                      children: [
                        SettingsRow(
                          icon: Icons.interests_outlined,
                          title: 'Edit interests & topics',
                          trailing:
                              Icon(Icons.chevron_right, color: cs.outlineVariant),
                          onTap: () => Get.toNamed(InterestsScreen.routeName),
                        ),
                        SettingsRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy',
                          trailing:
                              Icon(Icons.chevron_right, color: cs.outlineVariant),
                          onTap: () =>
                              Get.toNamed(TermsAndPrivacyScreen.routeName),
                        ),
                        SettingsRow(
                          icon: Icons.logout,
                          title: 'Sign out',
                          destructive: true,
                          last: true,
                          onTap: () => showCupertinoDialog(
                            context: context,
                            builder: (_) => const SignOutDialog(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() => Center(
                          child: Text(
                            settings.appVersion.value,
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
