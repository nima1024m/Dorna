import 'package:flutter/foundation.dart';

class TelemetryService {
  static void emitEvent(String name, {Map<String, dynamic>? properties}) {
    final event = {
      'name': name,
      'timestamp': DateTime.now().toIso8601String(),
      if (properties != null) 'properties': properties,
    };
    // For now, we'll just print the event to the console.
    // In a real-world scenario, this would send the event to a telemetry backend.
    debugPrint('Telemetry Event: $event');
  }
}
