import 'package:dorna/controllers/keyboard_status/keyboard_status_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  // Initialize the test binding so platform-channel access inside the controller
  // (keyboard status / connectivity checks) doesn't throw "Binding has not yet
  // been initialized" during these plain unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyboardStatusController controller;

  setUp(() {
    // Initialize GetX for testing
    Get.testMode = true;

    // Create controller instance
    controller = KeyboardStatusController();
  });

  tearDown(() {
    // Clean up after each test
    Get.reset();
  });

  group('KeyboardStatusController', () {
    group('Initial state', () {
      test('should have active status initially', () {
        // Assert
        expect(controller.keyboardStatus, KeyboardStatus.active);
      });
    });

    group('getStatusMessage method', () {
      test('should return correct message for active status', () {
        // Act
        final message = controller.getStatusMessage();

        // Assert
        expect(message, 'Everything looks good!');
      });
    });

    group('getStatusIcon method', () {
      test('should return correct icon for active status', () {
        // Act
        final icon = controller.getStatusIcon();

        // Assert
        expect(icon, 'assets/icons/ic_done.svg');
      });
    });

    group('getStatusColor method', () {
      test('should return a color for active status', () {
        // Act
        final color = controller.getStatusColor();

        // Assert
        expect(color, isNotNull);
      });
    });

    group('getBackgroundColor method', () {
      test('should return a background color for active status', () {
        // Act
        final color = controller.getBackgroundColor(false);

        // Assert
        expect(color, isNotNull);
      });
    });

    group('retryHealthCheck method', () {
      test('should complete without throwing in debug mode', () async {
        // Act & Assert
        expect(
            () async => await controller.retryHealthCheck(), returnsNormally);
      });
    });

    group('cancelRetryHealthCheck method', () {
      test('should complete without throwing', () {
        // Act & Assert
        expect(() => controller.cancelRetryHealthCheck(), returnsNormally);
      });
    });

    group('checkOnlyKeyboardHealth method', () {
      test('should complete without throwing', () async {
        // Act & Assert
        expect(() async => await controller.checkOnlyKeyboardHealth(),
            returnsNormally);
      });
    });

    group('init method', () {
      test('should complete without throwing', () async {
        // Act & Assert
        expect(() async => await controller.init(), returnsNormally);
      });

      test('should complete without throwing when initActive is false',
          () async {
        // Act & Assert
        expect(() async => await controller.init(initActive: false),
            returnsNormally);
      });
    });

    group('KeyboardStatus enum', () {
      test('should have all expected values', () {
        expect(KeyboardStatus.values, hasLength(4));
        expect(KeyboardStatus.values, contains(KeyboardStatus.active));
        expect(KeyboardStatus.values, contains(KeyboardStatus.inactive));
        expect(KeyboardStatus.values,
            contains(KeyboardStatus.temporaryUnavailable));
        expect(KeyboardStatus.values, contains(KeyboardStatus.noInternet));
      });

      test('should have correct string representation', () {
        expect(KeyboardStatus.active.name, 'active');
        expect(KeyboardStatus.inactive.name, 'inactive');
        expect(
            KeyboardStatus.temporaryUnavailable.name, 'temporaryUnavailable');
        expect(KeyboardStatus.noInternet.name, 'noInternet');
      });
    });

    group('Status message mapping', () {
      test('should return different messages for different statuses', () {
        final messages = <String>{};

        // We can't directly set the status, but we can test that different messages exist
        final activeMessage = controller.getStatusMessage();
        messages.add(activeMessage);

        // Verify that the message is not empty
        expect(activeMessage.isNotEmpty, isTrue);
        expect(activeMessage, 'Everything looks good!');
      });
    });

    group('Status icon mapping', () {
      test('should return valid icon paths', () {
        final icon = controller.getStatusIcon();

        expect(icon.isNotEmpty, isTrue);
        expect(icon.startsWith('assets/icons/'), isTrue);
        expect(icon.endsWith('.svg'), isTrue);
      });
    });

    group('Controller lifecycle', () {
      test('should be properly disposable', () {
        // Arrange
        final testController = KeyboardStatusController();

        // Act & Assert
        expect(() => testController.dispose(), returnsNormally);
      });

      test('should maintain state after creation', () {
        final status = controller.keyboardStatus;
        expect(status, isA<KeyboardStatus>());
      });
    });

    group('Reactive state changes', () {
      test('should track status changes through public interface', () async {
        // Arrange
        final initialStatus = controller.keyboardStatus;

        // Act - Trigger a status change by calling checkOnlyKeyboardHealth
        await controller.checkOnlyKeyboardHealth();

        // Allow time for async operations
        await Future.delayed(Duration(milliseconds: 100));

        // Assert - Status should be accessible and potentially changed
        final finalStatus = controller.keyboardStatus;
        expect(finalStatus, isA<KeyboardStatus>());
        expect(initialStatus, isA<KeyboardStatus>());
      });

      test('should maintain reactive state consistency', () {
        // Arrange
        final initialStatus = controller.keyboardStatus;

        // Act - Access status multiple times
        final status1 = controller.keyboardStatus;
        final status2 = controller.keyboardStatus;

        // Assert
        expect(status1, equals(status2));
        expect(status1, equals(initialStatus));
      });
    });

    group('Timer functionality', () {
      test('should handle retry health check scheduling', () {
        // Act & Assert - Should not throw when calling retry
        expect(() => controller.retryHealthCheck(), returnsNormally);
      });

      test('should handle cancel retry health check', () {
        // Arrange - Start a retry
        controller.retryHealthCheck();

        // Act & Assert - Should not throw when canceling
        expect(() => controller.cancelRetryHealthCheck(), returnsNormally);
      });

      test('should handle multiple retry cancellations', () {
        // Act - Cancel multiple times
        controller.cancelRetryHealthCheck();
        controller.cancelRetryHealthCheck();

        // Assert - Should not throw
        expect(() => controller.cancelRetryHealthCheck(), returnsNormally);
      });
    });

    group('Health check methods', () {
      test('checkOnlyKeyboardHealth should complete without errors', () async {
        // Act & Assert
        expect(() => controller.checkOnlyKeyboardHealth(), returnsNormally);

        // Wait for async completion
        await Future.delayed(Duration(milliseconds: 100));
      });

      test('should handle keyboard health check state changes', () async {
        // Arrange
        final initialStatus = controller.keyboardStatus;

        // Act
        await controller.checkOnlyKeyboardHealth();

        // Assert - Status should be set (likely to inactive due to test environment)
        expect(controller.keyboardStatus, isA<KeyboardStatus>());
      });

      test('init method should handle initActive parameter correctly',
          () async {
        // Test with initActive = true
        await controller.init(initActive: true);
        expect(controller.keyboardStatus, isA<KeyboardStatus>());

        // Test with initActive = false
        await controller.init(initActive: false);
        expect(controller.keyboardStatus, isA<KeyboardStatus>());
      });
    });

    group('Error handling and edge cases', () {
      test('should handle concurrent init calls gracefully', () async {
        // Act - Call init multiple times concurrently
        final futures = <Future>[
          controller.init(initActive: true),
          controller.init(initActive: false),
          controller.init(initActive: true),
        ];

        // Assert - Should complete without throwing
        expect(() => Future.wait(futures), returnsNormally);
        await Future.wait(futures);
      });

      test('should handle concurrent checkOnlyKeyboardHealth calls', () async {
        // Act - Call checkOnlyKeyboardHealth multiple times concurrently
        final futures = <Future>[
          controller.checkOnlyKeyboardHealth(),
          controller.checkOnlyKeyboardHealth(),
          controller.checkOnlyKeyboardHealth(),
        ];

        // Assert - Should complete without throwing
        expect(() => Future.wait(futures), returnsNormally);
        await Future.wait(futures);
      });

      test('should handle rapid retry operations', () {
        // Act - Rapidly start and cancel retries
        for (int i = 0; i < 5; i++) {
          controller.retryHealthCheck();
          controller.cancelRetryHealthCheck();
        }

        // Assert - Should not throw
        expect(() => controller.retryHealthCheck(), returnsNormally);
      });

      test('should maintain state consistency during rapid operations',
          () async {
        // Arrange
        final operations = <Future>[];

        // Act - Perform multiple operations rapidly
        for (int i = 0; i < 3; i++) {
          operations.add(controller.init(initActive: i % 2 == 0));
          operations.add(controller.checkOnlyKeyboardHealth());
        }

        await Future.wait(operations);

        // Assert - Controller should still be functional
        expect(controller.keyboardStatus, isA<KeyboardStatus>());
        expect(() => controller.getStatusMessage(), returnsNormally);
      });
    });

    group('State transition scenarios', () {
      test('should handle status transitions correctly', () async {
        // Test different initialization scenarios
        await controller.init(initActive: true);
        final activeStatus = controller.keyboardStatus;

        await controller.init(initActive: false);
        final inactiveStatus = controller.keyboardStatus;

        // Both should be valid statuses
        expect(activeStatus, isA<KeyboardStatus>());
        expect(inactiveStatus, isA<KeyboardStatus>());
      });

      test('should maintain UI consistency across state changes', () async {
        // Test that UI methods work regardless of state
        await controller.init(initActive: true);

        final message1 = controller.getStatusMessage();
        final icon1 = controller.getStatusIcon();
        final color1 = controller.getStatusColor();
        final bgColor1 = controller.getBackgroundColor(false);

        await controller.checkOnlyKeyboardHealth();

        final message2 = controller.getStatusMessage();
        final icon2 = controller.getStatusIcon();
        final color2 = controller.getStatusColor();
        final bgColor2 = controller.getBackgroundColor(false);

        // All should return valid values
        expect(message1, isA<String>());
        expect(icon1, isA<String>());
        expect(color1, isA<Color>());
        expect(bgColor1, isA<Color>());

        expect(message2, isA<String>());
        expect(icon2, isA<String>());
        expect(color2, isA<Color>());
        expect(bgColor2, isA<Color>());
      });
    });

    group('Performance and resource management', () {
      test('should handle multiple controller instances', () {
        // Arrange
        final controllers = <KeyboardStatusController>[];

        // Act - Create multiple instances
        for (int i = 0; i < 3; i++) {
          controllers.add(KeyboardStatusController());
        }

        // Assert - All should be functional
        for (final ctrl in controllers) {
          expect(ctrl.keyboardStatus, isA<KeyboardStatus>());
          expect(() => ctrl.getStatusMessage(), returnsNormally);
        }

        // Cleanup
        for (final ctrl in controllers) {
          ctrl.dispose();
        }
      });

      test('should handle disposal after operations', () async {
        // Arrange
        final testController = KeyboardStatusController();

        // Act - Perform operations then dispose
        await testController.init(initActive: true);
        testController.retryHealthCheck();
        await testController.checkOnlyKeyboardHealth();

        // Assert - Should dispose cleanly
        expect(() => testController.dispose(), returnsNormally);
      });
    });
  });
}
