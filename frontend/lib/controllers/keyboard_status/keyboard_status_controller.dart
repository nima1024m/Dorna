import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';

import '../../config/api_client.dart';
import '../../services/keyboard_service.dart';
import '../../services/telemetry_service.dart';

enum KeyboardStatus {
  active,
  inactive,
  temporaryUnavailable,
  noInternet,
}

class KeyboardStatusController extends GetxController {
  final KeyboardService _keyboardService = KeyboardService();
  final ApiClient _apiClient = ApiClient();
  final Rx<KeyboardStatus> _keyboardStatus = KeyboardStatus.active.obs;

  RxBool loading = false.obs;

  Timer? _timerHealthCheckGreen;
  Timer? _timerHealthCheckYellow;
  Timer? _timerHealthCheckKeyboard;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasConnected = true;

  KeyboardStatus get keyboardStatus => _keyboardStatus.value;

  init({bool initActive = true}) async {
    loading.value = true;
    TelemetryService.emitEvent('health_flow_started');
    if (initActive) {
      _keyboardStatus.value = KeyboardStatus.active;
    }

    var isCustomKeyboardEnabled =
        await _keyboardService.isCustomKeyboardEnabled();
    if (!isCustomKeyboardEnabled) {
      _keyboardStatus.value = KeyboardStatus.inactive;
      TelemetryService.emitEvent('health_check_keyboard_ready', properties: {
        'status': 'fail',
        'reason': 'keyboard_not_enabled',
      });
      loading.value = false;
      return;
    }

    var isCustomKeyboardHasFullAccess =
        await _keyboardService.hasFullAccessRuntime();
    if (!isCustomKeyboardHasFullAccess) {
      _keyboardStatus.value = KeyboardStatus.inactive;
      TelemetryService.emitEvent('health_check_keyboard_ready', properties: {
        'status': 'fail',
        'reason': 'keyboard_has_no_full_access',
      });
      loading.value = false;
      return;
    }
    TelemetryService.emitEvent('health_check_keyboard_ready', properties: {
      'status': 'ok',
    });

    // Keyboard is active, now check health
    await _performHealthChecks();
  }

  /// Performs health checks for API and AI services when keyboard is active
  Future<void> _performHealthChecks() async {
    // Check API health first
    final isApiHealthy = await _checkApiHealth();
    if (isApiHealthy == null) {
      _keyboardStatus.value = KeyboardStatus.noInternet;
      TelemetryService.emitEvent('health_state_rendered ', properties: {
        'state': keyboardStatus.name,
      });
      loading.value = false;
      return;
    }
    if (!isApiHealthy) {
      _keyboardStatus.value = KeyboardStatus.temporaryUnavailable;
      TelemetryService.emitEvent('health_state_rendered ', properties: {
        'state': keyboardStatus.name,
      });
      loading.value = false;
      return;
    }

    // If API is healthy, check AI health
    final isAiHealthy = await _checkAiHealth();
    if (isAiHealthy == null) {
      _keyboardStatus.value = KeyboardStatus.noInternet;
      TelemetryService.emitEvent('health_state_rendered ', properties: {
        'state': keyboardStatus.name,
      });
      loading.value = false;
      return;
    }
    if (!isAiHealthy) {
      _keyboardStatus.value = KeyboardStatus.temporaryUnavailable;
      TelemetryService.emitEvent('health_state_rendered ', properties: {
        'state': keyboardStatus.name,
      });
      loading.value = false;
      return;
    }
    TelemetryService.emitEvent('health_state_rendered ', properties: {
      'state': keyboardStatus.name,
    });

    // Both API and AI are healthy
    _keyboardStatus.value = KeyboardStatus.active;
    loading.value = false;
  }

  /// Checks the health of the API endpoint.
  ///
  /// Returns a [Future<bool>] indicating if the API is healthy.
  /// Returns false if there's no internet connection, error status codes 400-600,
  /// or if the response is not {"status": "OK"}.
  Future<bool?> _checkApiHealth() async {
    try {
      final response = await _apiClient.request(
        url: 'system/api-health',
        method: ApiMethod.get,
        showError: false,
        timeout: const Duration(seconds: 5),
        telemetryEventName: 'health_check_backend',
      );

      // Check for error status codes between 400-600
      if (response?.statusCode != null &&
          response!.statusCode! >= 400 &&
          response.statusCode! < 600) {
        return false;
      }

      // Check for successful response with correct format
      if (response?.statusCode == 200 &&
          response?.data != null &&
          response?.data is Map &&
          response?.data['status'] == 'OK') {
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == null) {
          return null;
        }
      }
      return false;
    }
  }

  /// Checks the health of the AI endpoint.
  ///
  /// Returns a [Future<bool>] indicating if the AI service is healthy.
  /// Returns false if there's no internet connection, error status codes 400-600,
  /// or if the response is not {"status": "OK"}.
  Future<bool?> _checkAiHealth() async {
    try {
      final response = await _apiClient.request(
        url: 'system/ai-health',
        method: ApiMethod.get,
        showError: false,
        timeout: const Duration(seconds: 5),
        telemetryEventName: 'health_check_ai',
      );

      // Check for error status codes between 400-600
      if (response?.statusCode != null &&
          response!.statusCode! >= 400 &&
          response.statusCode! < 600) {
        return false;
      }

      // Check for successful response with correct format
      if (response?.statusCode == 200 &&
          response?.data != null &&
          response?.data is Map &&
          response?.data['status'] == 'OK') {
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == null) {
          return null;
        }
      }
      return false;
    }
  }

  checkOnlyKeyboardHealth() async {
    var isCustomKeyboardEnabled =
        await _keyboardService.isCustomKeyboardEnabled();
    if (!isCustomKeyboardEnabled) {
      _keyboardStatus.value = KeyboardStatus.inactive;
      TelemetryService.emitEvent('health_check_keyboard_ready', properties: {
        'status': 'fail',
        'reason': 'keyboard_not_enabled',
      });
      return;
    }

    var isCustomKeyboardHasFullAccess =
        await _keyboardService.hasFullAccessRuntime();
    if (!isCustomKeyboardHasFullAccess) {
      _keyboardStatus.value = KeyboardStatus.inactive;
      TelemetryService.emitEvent('health_check_keyboard_ready', properties: {
        'status': 'fail',
        'reason': 'keyboard_has_no_full_access',
      });
      return;
    }
    TelemetryService.emitEvent('health_check_keyboard_ready', properties: {
      'status': 'ok',
    });
  }

  /// This method is called when the keyboard status is temporaryUnavailable or noInternet.
  /// It retries the health checks every 60 seconds until the keyboard status is active.
  /// If keyboard status is active, it retries the health checks every 1 hour.
  retryHealthCheck() async {
    if (kDebugMode) {
      return;
    }
    TelemetryService.emitEvent('health_auto_retry_scheduled');

    cancelRetryHealthCheck();
    if (_keyboardStatus.value == KeyboardStatus.active) {
      _timerHealthCheckGreen =
          Timer.periodic(const Duration(minutes: 60), (timer) async {
        TelemetryService.emitEvent('health_auto_retry_fired');
        await init(initActive: false);
        timer.cancel();
        cancelRetryHealthCheck();
        retryHealthCheck();
      });
    } else if (_keyboardStatus.value == KeyboardStatus.temporaryUnavailable ||
        _keyboardStatus.value == KeyboardStatus.noInternet) {
      _timerHealthCheckYellow =
          Timer.periodic(const Duration(seconds: 60), (timer) async {
        TelemetryService.emitEvent('health_auto_retry_fired');
        await init(initActive: false);
        timer.cancel();
        cancelRetryHealthCheck();
        if (_keyboardStatus.value != KeyboardStatus.active) {
          retryHealthCheck();
        }
      });
    }
    _timerHealthCheckKeyboard =
        Timer.periodic(const Duration(seconds: 35), (timer) async {
      checkOnlyKeyboardHealth();
    });
  }

  cancelRetryHealthCheck() {
    _timerHealthCheckGreen?.cancel();
    _timerHealthCheckYellow?.cancel();
    _timerHealthCheckKeyboard?.cancel();
  }

  cancelConnectivitySubscription() {
    _connectivitySubscription?.cancel();
  }

  /// Initializes connectivity monitoring to detect internet connection changes
  initConnectivityMonitoring() async {
    _connectivitySubscription?.cancel();
    _wasConnected = (await Connectivity().checkConnectivity()).any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        EasyDebounce.cancel('initConnectivityMonitoring');
        EasyDebounce.debounce(
            'initConnectivityMonitoring', const Duration(seconds: 2), () {
          _onConnectivityChanged(results);
        });
      },
    );
  }

  /// Handles connectivity changes and triggers health checks when connection is restored
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    bool isConnected = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    TelemetryService.emitEvent('connectivity_changed', properties: {
      'connection_types': results.map((r) => r.name).toList(),
      'is_connected': isConnected,
      'was_connected': _wasConnected,
    });

    // If connection was restored, recheck health
    if (isConnected && !_wasConnected) {
      _wasConnected = isConnected;
      TelemetryService.emitEvent('connectivity_restored');

      // Cancel existing timers and recheck health
      cancelRetryHealthCheck();

      await init();
      // Restart health check timers
      retryHealthCheck();
    }
    // If connection was restored, recheck health
    else if (!isConnected && _wasConnected) {
      _wasConnected = isConnected;
      TelemetryService.emitEvent('connectivity_lost');

      // Cancel existing timers and recheck health
      cancelRetryHealthCheck();

      await init();
      // Restart health check timers
      retryHealthCheck();
    }

    _wasConnected = isConnected;
  }

  String getStatusMessage() {
    if (loading.value) {
      return 'Checking...';
    }
    switch (_keyboardStatus.value) {
      case KeyboardStatus.active:
        return 'Everything looks good!';
      case KeyboardStatus.inactive:
        return 'Keyboard is not active.';
      case KeyboardStatus.temporaryUnavailable:
        return 'Service temporary unavailable, We’re fixing it! Please try again in a bit.';
      case KeyboardStatus.noInternet:
        return 'No internet connection, Please check your Wi-Fi or cellular network.';
    }
  }

  String getStatusIcon() {
    switch (_keyboardStatus.value) {
      case KeyboardStatus.active:
        return 'assets/icons/ic_done.svg';
      case KeyboardStatus.inactive:
        return 'assets/icons/ic_alert.svg';
      case KeyboardStatus.temporaryUnavailable:
        return 'assets/icons/ic_warning.svg';
      case KeyboardStatus.noInternet:
        return 'assets/icons/ic_warning.svg';
    }
  }

  Color getStatusColor() {
    if (loading.value) {
      return AppColors.primaryColor().withOpacity(0.15);
    }
    switch (_keyboardStatus.value) {
      case KeyboardStatus.active:
        return AppColors.successText; // Green
      case KeyboardStatus.inactive:
        return AppColors.errorText; // Red
      case KeyboardStatus.temporaryUnavailable:
        return AppColors.warningText2; // Orange
      case KeyboardStatus.noInternet:
        return AppColors.warningText2; // Orange
    }
  }

  Color getBackgroundColor(bool isDarkMode) {
    if (loading.value) {
      return isDarkMode
          ? Colors.white.withOpacity(0.05)
          : const Color(0xff232E36).withOpacity(0.05);
    }
    switch (_keyboardStatus.value) {
      case KeyboardStatus.active:
        return AppColors.successText.withOpacity(0.05); // Light green
      case KeyboardStatus.inactive:
        return AppColors.errorText.withOpacity(0.05); // Light red
      case KeyboardStatus.temporaryUnavailable:
        return AppColors.warningText2.withOpacity(0.05); // Light orange
      case KeyboardStatus.noInternet:
        return AppColors.warningText2.withOpacity(0.05); // Light orange
    }
  }
}
