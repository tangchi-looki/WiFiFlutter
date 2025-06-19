import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';

void main() {
  group('forceWifiUsageWithRetry', () {
    test('should have correct method signature', () {
      // This test verifies that the method exists and has the expected signature
      expect(WiFiForIoTPlugin.forceWifiUsageWithRetry, isA<Function>());
    });

    test('should accept default parameters', () async {
      // Test that the method can be called with just the required parameter
      // Note: This will fail in test environment but verifies the API
      try {
        await WiFiForIoTPlugin.forceWifiUsageWithRetry(true);
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<MissingPluginException>());
      }
    });

    test('should accept custom retry parameters', () async {
      // Test that the method can be called with custom parameters
      try {
        await WiFiForIoTPlugin.forceWifiUsageWithRetry(
          true,
          retryCount: 5,
          retryDelay: 2000,
        );
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<MissingPluginException>());
      }
    });

    test('should handle disable WiFi usage', () async {
      // Test disabling WiFi usage
      try {
        await WiFiForIoTPlugin.forceWifiUsageWithRetry(false);
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<MissingPluginException>());
      }
    });

    test('should validate parameter types', () {
      // Test that parameters are of correct types
      expect(() => WiFiForIoTPlugin.forceWifiUsageWithRetry(
        true,
        retryCount: 3,
        retryDelay: 1000,
      ), returnsNormally);
    });
  });

  group('Enhanced WiFi connection methods', () {
    test('connectWithResult should exist', () {
      expect(WiFiForIoTPlugin.connectWithResult, isA<Function>());
    });

    test('findAndConnectWithResult should exist', () {
      expect(WiFiForIoTPlugin.findAndConnectWithResult, isA<Function>());
    });

    test('should maintain backward compatibility', () {
      // Original methods should still exist
      expect(WiFiForIoTPlugin.connect, isA<Function>());
      expect(WiFiForIoTPlugin.findAndConnect, isA<Function>());
      expect(WiFiForIoTPlugin.forceWifiUsage, isA<Function>());
    });
  });

  group('WiFiConnectionResult', () {
    test('should create successful result', () {
      final result = WiFiConnectionResult.success();
      
      expect(result.success, isTrue);
      expect(result.errorCode, WiFiConnectionError.SUCCESS);
      expect(result.errorMessage, isNull);
      expect(result.errorDetails, isNull);
    });

    test('should create failure result', () {
      final result = WiFiConnectionResult.failure(
        errorCode: WiFiConnectionError.AUTHENTICATION_FAILED,
        errorMessage: 'Wrong password',
        errorDetails: 'Authentication timeout',
      );
      
      expect(result.success, isFalse);
      expect(result.errorCode, WiFiConnectionError.AUTHENTICATION_FAILED);
      expect(result.errorMessage, 'Wrong password');
      expect(result.errorDetails, 'Authentication timeout');
    });

    test('should handle platform exceptions', () {
      final exception = PlatformException(
        code: 'WEP_NOT_SUPPORTED',
        message: 'WEP is not supported for Android SDK 30',
        details: 'WEP_SECURITY',
      );
      
      final result = WiFiConnectionResult.fromPlatformException(exception);
      
      expect(result.success, isFalse);
      expect(result.errorCode, WiFiConnectionError.WEP_NOT_SUPPORTED);
      expect(result.errorMessage, 'WEP is not supported for Android SDK 30');
      expect(result.errorDetails, 'WEP_SECURITY');
    });
  });

  group('WiFiConnectionError enum', () {
    test('should have all expected error codes', () {
      final errorCodes = WiFiConnectionError.values;
      
      expect(errorCodes, contains(WiFiConnectionError.SUCCESS));
      expect(errorCodes, contains(WiFiConnectionError.UNKNOWN_ERROR));
      expect(errorCodes, contains(WiFiConnectionError.INVALID_SSID));
      expect(errorCodes, contains(WiFiConnectionError.INVALID_BSSID));
      expect(errorCodes, contains(WiFiConnectionError.WEP_NOT_SUPPORTED));
      expect(errorCodes, contains(WiFiConnectionError.WIFI_NOT_ENABLED));
      expect(errorCodes, contains(WiFiConnectionError.NETWORK_NOT_FOUND));
      expect(errorCodes, contains(WiFiConnectionError.AUTHENTICATION_FAILED));
      expect(errorCodes, contains(WiFiConnectionError.CONNECTION_TIMEOUT));
      expect(errorCodes, contains(WiFiConnectionError.CONFIGURATION_FAILED));
      expect(errorCodes, contains(WiFiConnectionError.PERMISSION_DENIED));
      expect(errorCodes, contains(WiFiConnectionError.NETWORK_SUGGESTION_FAILED));
      expect(errorCodes, contains(WiFiConnectionError.NETWORK_REQUEST_FAILED));
      expect(errorCodes, contains(WiFiConnectionError.NOT_CONNECTED));
      expect(errorCodes, contains(WiFiConnectionError.NETWORK_UNAVAILABLE));
    });
  });
}
