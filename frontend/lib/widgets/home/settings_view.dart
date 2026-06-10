import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:dorna/screens/settings/contact_us_screen.dart';
import 'package:dorna/screens/settings/terms_and_privacy_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:dorna/widgets/ui/custom_list_tile.dart';
import 'package:dorna/widgets/ui/custom_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/settings/settings_controller.dart';
import '../../screens/settings/about_us_screen.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final SettingsController settingsController = Get.find();

  void onChangeThemeTap(bool value, ctx) {
    settingsController.setDarkTheme(value);
    final newTheme = settingsController.isDarkTheme.value
        ? settingsController.darkTheme
        : settingsController.lightTheme;

    ThemeSwitcher.of(ctx).changeTheme(
      theme: newTheme,
      isReversed: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Obx(() => ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            ThemeSwitcher(builder: (ctx) {
              return CustomSwitchTile(
                title: 'Dark theme',
                value: settingsController.isDarkTheme.value,
                onChanged: (value) => onChangeThemeTap(value, ctx),
                leadingIcon: 'assets/icons/ic_moon.svg',
              );
            }),
            // const SizedBox(height: 16),
            // CustomSwitchTile(
            //   title: 'Switch through languages',
            //   value: settingsController.switchThroughLanguages.value,
            //   onChanged: settingsController.setSwitchThroughLanguages,
            //   leadingIcon: 'assets/icons/ic_globe.svg',
            //   subtitle: 'When enabled, by tapping the globe key the keyboard will switch between Dorna languages instead of switching to the next keyboard. Long-press the globe to bring up the option to switch to another keyboard.',
            // ),
            const SizedBox(height: 16),
            CustomSwitchTile(
              title: 'Collect data',
              value: settingsController.collectData.value,
              onChanged: settingsController.setCollectData,
              leadingIcon: 'assets/icons/ic_database.svg',
              subtitle:
                  'We learn from your mistakes to help you improve grammar, writing, and speaking. Only grammar errors are stored — never personal data.',
            ),
            const SizedBox(height: 16),
            CustomSwitchTile(
              title: 'Auto-Correction',
              value: settingsController.isAutoCorrectionEnabled.value,
              onChanged: settingsController.setAutoCorrectionEnabled,
              leadingIcon: 'assets/icons/ic_auto_correction.svg',
              subtitle:
                  'When enabled, Dorna keybaord will automatically correct misspelled words.',
            ),
            const SizedBox(height: 16),
            CustomListTile(
              title: 'Contact us',
              onTap: () {
                Get.toNamed(ContactUsScreen.routeName);
              },
              leading: SvgPicture.asset(
                'assets/icons/ic_headset.svg',
                width: 22,
                height: 22,
                color: AppColors.textMain(),
              ),
            ),
            const SizedBox(height: 16),
            CustomListTile(
              title: 'Share with friends',
              onTap: null,
              showArrow: false,
              isEnabled: false,
              leading: SvgPicture.asset(
                'assets/icons/ic_share.svg',
                width: 22,
                height: 22,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                // color: AppColors.textMain(),
              ),
            ),
            const SizedBox(height: 16),
            CustomListTile(
              title: 'Terms and Privacy',
              onTap: () {
                Get.toNamed(TermsAndPrivacyScreen.routeName);
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SvgPicture.asset(
                  'assets/icons/ic_terms.svg',
                  width: 18,
                  height: 18,
                  color: AppColors.textMain(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomListTile(
              title: 'About Dorna',
              onTap: () {
                Get.toNamed(AboutUsScreen.routeName);
              },
              leading: SvgPicture.asset(
                'assets/icons/ic_info2.svg',
                width: 22,
                height: 22,
                color: AppColors.textMain(),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                settingsController.appVersion.value,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textMain(),
                      fontSize: 13.sp,
                    ),
              ),
            ),
          ],
        ));
  }
}
