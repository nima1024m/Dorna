import 'package:get/get.dart';

import '../auth/auth_controller.dart';

/// State for the redesigned **Profile / progress** tab.
///
/// Identity (name, avatar) is real. Streak, the three stat counters,
/// weak-areas, interests and the saved-phrase count are **placeholder/local** —
/// the backend has no streak/XP/stats and no saved-phrase store yet. F6 wires
/// stats/weak-areas (the latter can come from `GET /v1/assistant/learning-insights`)
/// and F1 wires saved phrases.
class ProfileProgressController extends GetxController {
  String get name {
    final full = Get.find<AuthController>().getUserDetails.fullName?.trim();
    return (full == null || full.isEmpty) ? 'there' : full.split(RegExp(r'\s+')).first;
  }

  // Placeholder progress data.
  final RxInt streakDays = 6.obs;
  final RxInt phrasesLearned = 24.obs;
  final RxInt conversations = 8.obs;
  final RxInt briefsHeard = 12.obs;
  final RxInt savedCount = 14.obs;
  final RxList<String> weakAreas = <String>['articles (a/an)', 'past tense'].obs;
  final RxList<String> interests =
      <String>['Tech', 'Music', 'Travel', 'Cooking'].obs;
}
