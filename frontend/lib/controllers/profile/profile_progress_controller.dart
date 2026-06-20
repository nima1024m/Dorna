import 'package:get/get.dart';

import '../../config/api_client.dart';
import '../auth/auth_controller.dart';

/// State for the redesigned **Profile / progress** tab.
///
/// Identity (name) is real. Streak + counters + weak-areas come from the F6
/// backend (`GET /v1/stats/me`); on first build it also records an app-open
/// ping (`POST /v1/stats/activity`) to advance the streak. Falls back to sample
/// values when the endpoint isn't deployed yet (no crash). Interests are still
/// a placeholder (onboarding taxonomy lands later); the saved-phrase count is
/// owned by `PhraseController` (F1).
class ProfileProgressController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  String get name {
    final full = Get.find<AuthController>().getUserDetails.fullName?.trim();
    return (full == null || full.isEmpty)
        ? 'there'
        : full.split(RegExp(r'\s+')).first;
  }

  // Sample fallbacks (replaced by the backend when reachable).
  final RxInt streakDays = 6.obs;
  final RxInt phrasesLearned = 24.obs;
  final RxInt conversations = 8.obs;
  final RxInt briefsHeard = 12.obs;
  final RxList<String> weakAreas =
      <String>['articles (a/an)', 'past tense'].obs;
  final RxList<String> interests =
      <String>['Tech', 'Music', 'Travel', 'Cooking'].obs;

  @override
  void onInit() {
    super.onInit();
    recordActivity(); // app-open ping; the response carries the fresh summary
  }

  Future<void> loadStats() async {
    try {
      final r = await _apiClient.request(
        url: 'v1/stats/me',
        method: ApiMethod.get,
        skipErrorStatusCodes: const [404],
      );
      if (r != null && r.statusCode == 200 && r.data is Map) {
        _apply(r.data as Map);
      }
    } catch (_) {}
  }

  Future<void> recordActivity() async {
    try {
      final r = await _apiClient.request(
        url: 'v1/stats/activity',
        method: ApiMethod.post,
        skipErrorStatusCodes: const [404],
      );
      if (r != null && r.statusCode == 200 && r.data is Map) {
        _apply(r.data as Map);
      } else {
        await loadStats();
      }
    } catch (_) {
      await loadStats();
    }
  }

  void _apply(Map data) {
    streakDays.value = (data['streak_days'] as int?) ?? streakDays.value;
    phrasesLearned.value =
        (data['phrases_learned'] as int?) ?? phrasesLearned.value;
    conversations.value = (data['conversations'] as int?) ?? conversations.value;
    briefsHeard.value = (data['briefs_heard'] as int?) ?? briefsHeard.value;
    final wa = data['weak_areas'];
    if (wa is List && wa.isNotEmpty) {
      weakAreas.assignAll(wa.map((e) => e.toString()));
    }
  }
}
