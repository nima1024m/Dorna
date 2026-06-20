import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/api_client.dart';

/// Push notifications via FCM (backend F7).
///
/// Registers the device's FCM token with the backend (auth-gated, so call once
/// the user is signed in — e.g. from MainShell), keeps it fresh, and routes
/// notification taps. Degrades silently if Firebase/permissions aren't ready or
/// the endpoint isn't deployed.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final ApiClient _api = ApiClient();
  bool _started = false;

  Future<void> init() async {
    if (_started || kIsWeb) return;
    _started = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) await _register(token);
      messaging.onTokenRefresh.listen(_register);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (_) {
      _started = false; // allow a later retry
    }
  }

  Future<void> _register(String token) async {
    try {
      await _api.request(
        url: 'v1/notifications/register-token',
        method: ApiMethod.post,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
        skipErrorStatusCodes: const [401, 404],
        showError: false,
      );
    } catch (_) {}
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && route.isNotEmpty) {
      try {
        Get.toNamed(route);
      } catch (_) {}
    }
  }
}
