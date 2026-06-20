import 'package:get/get.dart';

/// Local UI state for the redesigned Settings hub.
///
/// These toggles are **placeholder/local** — there is no backend for calendar
/// connection, location, daily-brief time, native-language preference or
/// "simple English tips" yet (they land in F3/F5 and a future user-settings
/// endpoint). The real, working controls (dark mode, sign-out) delegate to the
/// existing [SettingsController] / [AuthController]; only the placeholders live
/// here.
class SettingsHubController extends GetxController {
  final RxBool calendarConnected = false.obs;
  final RxBool locationOn = false.obs;
  final RxBool simpleEnglishTips = true.obs;
  final RxBool nativeLangFa = true.obs; // true → فارسی, false → English
  final RxString dailyBriefTime = '7:30 AM'.obs;

  String get nativeLangLabel => nativeLangFa.value ? 'فارسی' : 'English';

  void toggleCalendar(bool v) => calendarConnected.value = v;
  void toggleLocation(bool v) => locationOn.value = v;
  void toggleSimpleTips(bool v) => simpleEnglishTips.value = v;
  void toggleNativeLang() => nativeLangFa.toggle();
}
