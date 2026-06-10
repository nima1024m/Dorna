import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AndroidKeyboardService {
  static const platform = MethodChannel('com.dorna.app/keyboard');

  /// Check if the custom keyboard is enabled
  Future<bool> isCustomKeyboardEnabled() async {
    try {
      final bool result =
          await platform.invokeMethod('isCustomKeyboardEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to check keyboard status: ${e.message}");
      return false;
    }
  }

  /// Open Android input settings page for the user to enable the keyboard
  Future<void> openKeyboardSettings() async {
    try {
      await platform.invokeMethod('openKeyboardSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open keyboard settings: ${e.message}");
    }
  }
}
