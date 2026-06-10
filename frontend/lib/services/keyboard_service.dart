import 'package:flutter/services.dart';

class KeyboardService {
  static const MethodChannel _channel = MethodChannel('com.dorna.app/keyboard');

  // Opens the keyboard settings on iOS
  Future<void> openKeyboardSettings() async {
    try {
      await _channel.invokeMethod('openKeyboardSettings');
    } catch (e) {
      print('Error opening keyboard settings: $e');
    }
  }

  // Sets collect data consent (iOS via app group)
  Future<void> setCollectData(bool enabled) async {
    try {
      await _channel.invokeMethod('setCollectData', {'enabled': enabled});
      print('mylog setCollectData: $enabled');
    } catch (e) {
      print('Error setting collect data: $e');
    }
  }

  // Sets auto correction enabled (iOS via app group)
  Future<void> setAutoCorrectionEnabled(bool enabled) async {
    try {
      await _channel
          .invokeMethod('setAutoCorrectionEnabled', {'enabled': enabled});
      print('mylog setAutoCorrectionEnabled: $enabled');
    } catch (e) {
      print('Error setting auto correction: $e');
    }
  }

  // Checks if the custom keyboard is enabled
  Future<bool> isCustomKeyboardEnabled() async {
    try {
      final bool isEnabled =
          await _channel.invokeMethod('isCustomKeyboardEnabled');
      print('mylog isCustomKeyboardEnabled: $isEnabled');
      return isEnabled;
    } catch (e) {
      print('Error checking if custom keyboard is enabled: $e');
      return false;
    }
  }

  // Checks if the custom keyboard is currently selected/active in iOS keyboard selector
  Future<bool> isCustomKeyboardSelected() async {
    try {
      final bool isSelected =
          await _channel.invokeMethod('isCustomKeyboardSelected');
      return isSelected;
    } catch (e) {
      print('Error checking if custom keyboard is selected: $e');
      return false;
    }
  }

  // Checks full access by using UIInputViewController.hasFullAccess (iOS only)
  Future<bool> hasFullAccessRuntime() async {
    try {
      final bool hasAccess =
          await _channel.invokeMethod('hasFullAccessByUIInputViewController');
      print('mylog hasFullAccessByUIInputViewController: $hasAccess');
      return hasAccess;
    } catch (e) {
      print('Error checking full access via UIInputViewController: $e');
      return false;
    }
  }
  // Gets debug information about keyboard status (iOS only)
  Future<Map<String, dynamic>> getKeyboardDebugInfo() async {
    try {
      final Map<dynamic, dynamic> debugInfo =
          await _channel.invokeMethod('getKeyboardDebugInfo');
      print('mylog getKeyboardDebugInfo: $debugInfo');
      return Map<String, dynamic>.from(debugInfo);
    } catch (e) {
      print('Error getting keyboard debug info: $e');
      return {};
    }
  }

  // Gets the current selected keyboard name (iOS only)
  Future<String> getCurrentSelectedKeyboardName() async {
    try {
      final String keyboardName = await _channel.invokeMethod('getCurrentSelectedKeyboardName');
      print('mylog getCurrentSelectedKeyboardName: $keyboardName');
      return keyboardName;
    } catch (e) {
      print('Error getting current selected keyboard name: $e');
      return 'Unknown Keyboard';
    }
  }

  // Refreshes the full access status (iOS only)
  Future<void> refreshFullAccessStatus() async {
    try {
      await _channel.invokeMethod('refreshFullAccessStatus');
      print(
          'mylog refreshFullAccessStatus: Successfully refreshed full access status');
    } catch (e) {
      print('Error refreshing full access status: $e');
    }
  }

  // Refreshes the keyboard selection status (iOS only)
  Future<void> refreshKeyboardSelectionStatus() async {
    try {
      await _channel.invokeMethod('refreshKeyboardSelectionStatus');
      print(
          'mylog refreshKeyboardSelectionStatus: Successfully refreshed keyboard selection status');
    } catch (e) {
      print('Error refreshing keyboard selection status: $e');
    }
  }

  // Clears all app group data (iOS only)
  Future<void> clearAppGroupData() async {
    try {
      await _channel.invokeMethod('clearAppGroupData');
      print('mylog clearAppGroupData: Successfully cleared app group data');
    } catch (e) {
      print('Error clearing app group data: $e');
    }
  }

  // Gets the list of favorite tones
  Future<List<String>> getFavoriteTones() async {
    try {
      final List<dynamic> favorites = await _channel.invokeMethod('getFavoriteTones');
      print('mylog getFavoriteTones: $favorites');
      return favorites.map((e)=>e.toString()).toList();
    } catch (e) {
      print('Error getting favorite tones: $e');
      return [];
    }
  }

  // Adds a tone to favorites
  Future<void> addFavoriteTone(String toneName) async {
    try {
      await _channel.invokeMethod('addFavoriteTone', {'toneName': toneName});
      print('mylog addFavoriteTone: Successfully added $toneName');
    } catch (e) {
      print('Error adding favorite tone: $e');
    }
  }

  // Removes a tone from favorites
  Future<void> removeFavoriteTone(String toneName) async {
    try {
      await _channel.invokeMethod('removeFavoriteTone', {'toneName': toneName});
      print('mylog removeFavoriteTone: Successfully removed $toneName');
    } catch (e) {
      print('Error removing favorite tone: $e');
    }
  }

  // Saves both access and refresh tokens to app group with timestamp
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    double? timestamp,
  }) async {
    try {
      await _channel.invokeMethod('saveTokens', {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'timestamp': timestamp,
      });
      print(
          'mylog saveTokens: Successfully saved tokens to app group with timestamp: $timestamp');
    } catch (e) {
      print('Error saving tokens to app group: $e');
    }
  }

  // Gets the access token from app group
  Future<String?> getAccessToken() async {
    try {
      final String? token = await _channel.invokeMethod('getAccessToken');
      print(
          'mylog getAccessToken: Retrieved token from app group: ${token != null ? "***" : "null"}');
      return token;
    } catch (e) {
      print('Error getting access token from app group: $e');
      return null;
    }
  }

  // Gets the refresh token from app group
  Future<String?> getRefreshToken() async {
    try {
      final String? token = await _channel.invokeMethod('getRefreshToken');
      print(
          'mylog getRefreshToken: Retrieved token from app group: ${token != null ? "***" : "null"}');
      return token;
    } catch (e) {
      print('Error getting refresh token from app group: $e');
      return null;
    }
  }

  // Gets the token timestamp from app group
  Future<double?> getTokenTimestamp() async {
    try {
      final double? timestamp =
          await _channel.invokeMethod('getTokenTimestamp');
      print(
          'mylog getTokenTimestamp: Retrieved timestamp from app group: $timestamp');
      return timestamp;
    } catch (e) {
      print('Error getting token timestamp from app group: $e');
      return null;
    }
  }

  // Clears both tokens from app group
  Future<void> clearTokens() async {
    try {
      await _channel.invokeMethod('clearTokens');
      print('mylog clearTokens: Successfully cleared tokens from app group');
    } catch (e) {
      print('Error clearing tokens from app group: $e');
    }
  }
}
