import 'package:get/get.dart';

import '../../config/api_client.dart';

/// The conversation scene ids the backend understands. Must stay in sync with
/// the openers in `backend/app/services/conversation.py` (`_OPENERS`).
class ConversationScenes {
  ConversationScenes._();
  static const String smallTalk = 'small_talk';
  static const String networking = 'networking';
  static const String cafe = 'cafe';
  static const String work = 'work';
  static const String neighbours = 'neighbours';
}

class ConversationMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final String? correction;
  final String? tip;
  const ConversationMessage({
    required this.role,
    required this.text,
    this.correction,
    this.tip,
  });

  ConversationMessage withFeedback(String? correction, String? tip) =>
      ConversationMessage(
          role: role, text: text, correction: correction, tip: tip);
}

/// Drives a scene-based practice conversation (backend F4, text-first).
/// Voice in/out (STT/TTS) is a later layer; this is the typed conversation.
class ConversationController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  final RxList<ConversationMessage> messages = <ConversationMessage>[].obs;
  final RxBool isStarting = false.obs;
  final RxBool isSending = false.obs;
  final RxnString sessionId = RxnString();
  String scene = ConversationScenes.smallTalk;

  Future<void> start(String scene) async {
    this.scene = scene;
    messages.clear();
    sessionId.value = null;
    isStarting.value = true;
    try {
      final r = await _apiClient.request(
        url: 'v1/conversation/start',
        method: ApiMethod.post,
        data: {'scene': scene},
        skipErrorStatusCodes: const [404],
      );
      if (r != null && r.statusCode == 200 && r.data is Map) {
        sessionId.value = r.data['session_id']?.toString();
        final opener = r.data['opener']?.toString() ?? 'Hi! Let’s chat.';
        messages.add(ConversationMessage(role: 'assistant', text: opener));
      }
    } catch (_) {
    } finally {
      isStarting.value = false;
    }
  }

  Future<void> send(String text) async {
    final id = sessionId.value;
    final t = text.trim();
    if (id == null || t.isEmpty || isSending.value) return;

    messages.add(ConversationMessage(role: 'user', text: t));
    final userIndex = messages.length - 1;
    isSending.value = true;
    var ok = false;
    try {
      final r = await _apiClient.request(
        url: 'v1/conversation/$id/turn',
        method: ApiMethod.post,
        data: {'text': t},
        skipErrorStatusCodes: const [404],
      );
      if (r != null && r.statusCode == 200 && r.data is Map) {
        ok = true;
        final correction = (r.data['correction']?.toString() ?? '');
        final tip = (r.data['tip']?.toString() ?? '');
        if (correction.isNotEmpty || tip.isNotEmpty) {
          messages[userIndex] = messages[userIndex].withFeedback(
            correction.isNotEmpty ? correction : null,
            tip.isNotEmpty ? tip : null,
          );
        }
        final reply = r.data['reply']?.toString() ?? '…';
        messages.add(ConversationMessage(role: 'assistant', text: reply));
      }
    } catch (_) {
    } finally {
      // Don't leave the user's message hanging with no response.
      if (!ok) {
        messages.add(const ConversationMessage(
            role: 'assistant',
            text: "Sorry — I lost the thread there. Mind trying that again?"));
      }
      isSending.value = false;
    }
  }
}
