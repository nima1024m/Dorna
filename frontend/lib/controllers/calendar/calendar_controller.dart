import 'package:get/get.dart';

import '../../config/api_client.dart';
import '../../models/calendar_event_model.dart';

/// Calendar integration (backend F5).
///
/// Loads cached upcoming events and event-prep from the backend. The HTTP layer
/// is complete; the *acquisition* of events still needs the device-side wiring
/// (Google `serverAuthCode` via google_sign_in calendar scope → [connectGoogle];
/// or on-device calendar read via a plugin → [syncDeviceEvents]) plus the
/// owner's `GOOGLE_OAUTH_CLIENT_SECRET`. Degrades gracefully (empty) until then.
class CalendarController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  final RxList<CalendarEvent> events = <CalendarEvent>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  Future<void> loadEvents() async {
    isLoading.value = true;
    try {
      final r = await _apiClient.request(
        url: 'v1/calendar/events',
        method: ApiMethod.get,
        skipErrorStatusCodes: const [404],
      );
      if (r != null && r.statusCode == 200 && r.data is Map) {
        final list = (r.data['events'] as List?) ?? const [];
        events.assignAll(
            list.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Exchange a Google server-auth-code (obtained via google_sign_in with the
  /// calendar.readonly scope) for backend calendar access, then sync.
  Future<bool> connectGoogle(String serverAuthCode) async {
    try {
      final r = await _apiClient.request(
        url: 'v1/calendar/connect/google',
        method: ApiMethod.post,
        data: {'server_auth_code': serverAuthCode},
      );
      final ok = r != null && r.statusCode == 200;
      if (ok) {
        await _apiClient.request(
            url: 'v1/calendar/sync/google', method: ApiMethod.post);
        await loadEvents();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Push on-device (Apple/Android local) calendar events to the backend cache.
  Future<int> syncDeviceEvents(
      String provider, List<Map<String, dynamic>> deviceEvents) async {
    try {
      final r = await _apiClient.request(
        url: 'v1/calendar/events/sync',
        method: ApiMethod.post,
        data: {'provider': provider, 'events': deviceEvents},
      );
      if (r != null && r.statusCode == 200) {
        await loadEvents();
        return (r.data?['synced'] as int?) ?? deviceEvents.length;
      }
    } catch (_) {}
    return 0;
  }

  Future<Map<String, dynamic>?> eventPrep(String eventId) async {
    try {
      final r = await _apiClient.request(
        url: 'v1/calendar/events/$eventId/prep',
        method: ApiMethod.post,
      );
      if (r != null && r.statusCode == 200 && r.data is Map) {
        return (r.data as Map).cast<String, dynamic>();
      }
    } catch (_) {}
    return null;
  }
}
