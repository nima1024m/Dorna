import 'package:get/get.dart';

import '../../config/api_client.dart';
import '../../models/phrase_model.dart';

/// Phrase library + saved phrases (backend F1: `/v1/phrases`).
///
/// Degrades gracefully when the endpoint isn't deployed yet — failed calls
/// leave the lists empty rather than throwing (the owner must `make upgrade` +
/// deploy the backend for live data).
class PhraseController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  final RxList<Phrase> phrases = <Phrase>[].obs;
  final RxList<Phrase> saved = <Phrase>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingSaved = false.obs;

  int get savedCount => saved.length;

  @override
  void onInit() {
    super.onInit();
    fetchSaved();
  }

  Future<void> fetchPhrases({String? category}) async {
    isLoading.value = true;
    final qp = <String, dynamic>{};
    if (category != null) qp['category'] = category;
    try {
      final response = await _apiClient.request(
        url: 'v1/phrases',
        method: ApiMethod.get,
        queryParameters: qp,
        skipErrorStatusCodes: const [404],
      );
      if (response != null && response.statusCode == 200) {
        final items = (response.data?['items'] as List?) ?? [];
        phrases.assignAll(
            items.map((e) => Phrase.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // leave existing list as-is
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSaved() async {
    isLoadingSaved.value = true;
    try {
      final response = await _apiClient.request(
        url: 'v1/phrases/saved',
        method: ApiMethod.get,
        skipErrorStatusCodes: const [404],
      );
      if (response != null && response.statusCode == 200) {
        final items = (response.data?['items'] as List?) ?? [];
        saved.assignAll(
            items.map((e) => Phrase.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
    } finally {
      isLoadingSaved.value = false;
    }
  }

  bool isSaved(int phraseId) => saved.any((p) => p.id == phraseId);

  /// Optimistically toggle a phrase's saved state and sync with the backend,
  /// reverting on failure. Returns the resulting saved state.
  Future<bool> toggleSave(Phrase phrase) async {
    final wasSaved = isSaved(phrase.id);
    final nowSaved = !wasSaved;
    _applySaved(phrase, nowSaved);

    try {
      final response = await _apiClient.request(
        url: 'v1/phrases/${phrase.id}/save',
        method: nowSaved ? ApiMethod.post : ApiMethod.delete,
        skipErrorStatusCodes: const [404],
      );
      final ok = response != null && response.statusCode == 200;
      if (!ok) _applySaved(phrase, wasSaved); // revert
      return ok ? nowSaved : wasSaved;
    } catch (_) {
      _applySaved(phrase, wasSaved); // revert
      return wasSaved;
    }
  }

  void _applySaved(Phrase phrase, bool value) {
    final idx = phrases.indexWhere((p) => p.id == phrase.id);
    if (idx >= 0) phrases[idx] = phrases[idx].copyWith(saved: value);
    if (value) {
      if (!isSaved(phrase.id)) saved.add(phrase.copyWith(saved: true));
    } else {
      saved.removeWhere((p) => p.id == phrase.id);
    }
  }
}
