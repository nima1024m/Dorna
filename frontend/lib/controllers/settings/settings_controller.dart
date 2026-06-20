import 'package:dorna/services/keyboard_service.dart';
import 'package:dorna/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  final String _keyDarkTheme = 'settings.dark_theme';
  final String _keySwitchThroughLanguages = 'settings.switch_through_languages';
  final String _keyCollectData = 'settings.collect_data';
  final String _keyThemeSetManually = 'settings.theme_set_manually';
  final String _keyCollectDataSeen = 'settings.collect_data_seen';
  final String _keyIsKeyboardSelected = 'settings.is_keyboard_selected';
  final String _keyIsLoginSkipped = 'settings.is_login_skipped';
  final String _keyIsOnboardingCompleted = 'settings.is_onboarding_completed';
  final String _keyAutoCorrectionEnabled = 'settings.auto_correction_enabled';

  late SharedPreferences _prefs;

  final RxBool isDarkTheme = false.obs;
  final RxBool switchThroughLanguages = true.obs;
  final RxBool collectData = true.obs;
  final RxBool isThemeSetManually = false.obs;
  final RxBool isCollectDataSeen = false.obs;
  final RxBool isKeyboardSelected = false.obs;
  final RxBool isLoginSkipped = false.obs;
  final RxBool isOnboardingCompleted = false.obs;
  final RxBool isAutoCorrectionEnabled = false.obs;
  final RxString appVersion = ''.obs;

  loadAll() async {
    _prefs = await SharedPreferences.getInstance();
    final bool? themeSetManually = _prefs.getBool(_keyThemeSetManually);
    final bool? dark = _prefs.getBool(_keyDarkTheme);
    final bool? langs = _prefs.getBool(_keySwitchThroughLanguages);
    final bool? collect = _prefs.getBool(_keyCollectData);
    final bool? seen = _prefs.getBool(_keyCollectDataSeen);
    final bool? isLoginSkippedValue = _prefs.getBool(_keyIsLoginSkipped);
    final bool? isOnboardingCompletedValue =
        _prefs.getBool(_keyIsOnboardingCompleted);

    final bool? isAutoCorrectionEnabledValue =
        _prefs.getBool(_keyAutoCorrectionEnabled);

    if (isLoginSkippedValue != null) {
      isLoginSkipped.value = isLoginSkippedValue;
    }
    if (isOnboardingCompletedValue != null) {
      isOnboardingCompleted.value = isOnboardingCompletedValue;
    }
    final bool? isKeyboardSelectedValue =
        _prefs.getBool(_keyIsKeyboardSelected);

    if (themeSetManually != null) {
      isThemeSetManually.value = themeSetManually;
    }

    if (dark != null) {
      isDarkTheme.value = dark;
    } else if (!isThemeSetManually.value) {
      // If no manual setting exists, use OS theme
      isDarkTheme.value = _getSystemTheme();
    }

    if (langs != null) {
      switchThroughLanguages.value = langs;
    }
    if (isKeyboardSelectedValue != null) {
      isKeyboardSelected.value = isKeyboardSelectedValue;
    }
    if (seen != null) {
      isCollectDataSeen.value = seen;
    }
    if (collect != null) {
      collectData.value = collect;
    }
    if (isAutoCorrectionEnabledValue != null) {
      isAutoCorrectionEnabled.value = isAutoCorrectionEnabledValue;
    }

    // Propagate to iOS app group so the keyboard extension can respect it
    KeyboardService().setCollectData(collectData.value);
    KeyboardService().setAutoCorrectionEnabled(isAutoCorrectionEnabled.value);

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion.value = 'v${packageInfo.version}';
  }

  void setDarkTheme(bool value) {
    isDarkTheme.value = value;
    isThemeSetManually.value = true;
    _prefs.setBool(_keyDarkTheme, value);
    _prefs.setBool(_keyThemeSetManually, true);
  }

  void setSwitchThroughLanguages(bool value) {
    switchThroughLanguages.value = value;
    _prefs.setBool(_keySwitchThroughLanguages, value);
  }

  void setCollectData(bool value) {
    collectData.value = value;
    _prefs.setBool(_keyCollectData, value);
    // Propagate to iOS app group so the keyboard extension can respect it
    KeyboardService().setCollectData(value);
  }

  void setAutoCorrectionEnabled(bool value) {
    isAutoCorrectionEnabled.value = value;
    _prefs.setBool(_keyAutoCorrectionEnabled, value);
    // Propagate to iOS app group so the keyboard extension can respect it
    KeyboardService().setAutoCorrectionEnabled(value);
  }

  void setCollectDataSeen(bool value) {
    isCollectDataSeen.value = value;
    _prefs.setBool(_keyCollectDataSeen, value);
  }

  void setIsKeyboardSelected(bool value) {
    isKeyboardSelected.value = value;
    _prefs.setBool(_keyIsKeyboardSelected, value);
  }

  void setIsLoginSkipped(bool value) {
    isLoginSkipped.value = value;
    _prefs.setBool(_keyIsLoginSkipped, value);
  }

  void setIsOnboardingCompleted(bool value) {
    isOnboardingCompleted.value = value;
    _prefs.setBool(_keyIsOnboardingCompleted, value);
  }

  // Get system theme preference
  bool _getSystemTheme() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  // Reset to system theme
  void resetToSystemTheme() {
    isThemeSetManually.value = false;
    isDarkTheme.value = _getSystemTheme();
    _prefs.remove(_keyDarkTheme);
    _prefs.remove(_keyThemeSetManually);
  }

  // Theme-related methods
  ThemeData get lightTheme => _buildLightTheme();

  ThemeData get darkTheme => _buildDarkTheme();

  // Theme is now defined centrally by the design-token system; see
  // lib/theme/app_theme.dart (Phase 0 of the redesign).
  ThemeData _buildLightTheme() => AppTheme.light;

  ThemeData _buildDarkTheme() => AppTheme.dark;

  ThemeData get currentTheme => isDarkTheme.value ? darkTheme : lightTheme;
}


