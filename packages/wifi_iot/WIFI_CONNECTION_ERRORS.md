# WiFi Connection with Error Codes

This document describes the enhanced WiFi connection methods that provide detailed error information when connections fail.

## Overview

The original `connect()` and `findAndConnect()` methods only return a boolean value, making it difficult to understand why a connection failed. The new methods `connectWithResult()` and `findAndConnectWithResult()` return a `WiFiConnectionResult` object that contains detailed error information.

## New Methods

### connectWithResult()

```dart
Future<WiFiConnectionResult> connectWithResult(
  String ssid, {
  String? bssid,
  String? password,
  NetworkSecurity security = NetworkSecurity.NONE,
  bool joinOnce = true,
  bool withInternet = false,
  bool isHidden = false,
  int timeoutInSeconds = 30,
})
```

### findAndConnectWithResult()

```dart
Future<WiFiConnectionResult> findAndConnectWithResult(
  String ssid, {
  String? bssid,
  String? password,
  bool joinOnce = true,
  bool withInternet = false,
  int timeoutInSeconds = 30,
})
```

## WiFiConnectionResult

The `WiFiConnectionResult` class contains:

- `bool success`: Whether the connection was successful
- `WiFiConnectionError errorCode`: Specific error code
- `String? errorMessage`: Human-readable error message
- `String? errorDetails`: Additional error details

## Error Codes

| Error Code | Description | Common Causes |
|------------|-------------|---------------|
| `SUCCESS` | Connection successful | - |
| `UNKNOWN_ERROR` | Unknown error occurred | Unexpected system errors |
| `INVALID_SSID` | Invalid SSID format | SSID empty or > 32 characters |
| `INVALID_BSSID` | Invalid BSSID format | Malformed MAC address |
| `WEP_NOT_SUPPORTED` | WEP security not supported | Using WEP on Android SDK >= 29 |
| `WIFI_NOT_ENABLED` | WiFi is disabled | Device WiFi is turned off |
| `NETWORK_NOT_FOUND` | Network not found | SSID not in scan results |
| `AUTHENTICATION_FAILED` | Wrong password | Incorrect network password |
| `CONNECTION_TIMEOUT` | Connection timed out | Network slow to respond |
| `CONFIGURATION_FAILED` | Network config failed | Invalid network settings |
| `PERMISSION_DENIED` | Missing permissions | Location permission required |
| `NETWORK_SUGGESTION_FAILED` | Network suggestion failed | Android 10+ suggestion API error |
| `NETWORK_REQUEST_FAILED` | Network request failed | System network request error |
| `NOT_CONNECTED` | Device not connected | No active WiFi connection |
| `NETWORK_UNAVAILABLE` | Network unavailable | Network out of range or disabled |

## Usage Examples

### Basic Usage

```dart
final result = await WiFiForIoTPlugin.connectWithResult('MyNetwork', password: 'mypassword');

if (result.success) {
  print('Connected successfully!');
} else {
  print('Connection failed: ${result.errorCode}');
  print('Message: ${result.errorMessage}');
  print('Details: ${result.errorDetails}');
}
```

### Error Handling

```dart
final result = await WiFiForIoTPlugin.connectWithResult('MyNetwork', password: 'mypassword');

switch (result.errorCode) {
  case WiFiConnectionError.AUTHENTICATION_FAILED:
    showDialog(context, 'Wrong password. Please check your password and try again.');
    break;
  case WiFiConnectionError.NETWORK_NOT_FOUND:
    showDialog(context, 'Network not found. Make sure you\'re in range.');
    break;
  case WiFiConnectionError.PERMISSION_DENIED:
    showDialog(context, 'Location permission required to scan for networks.');
    break;
  case WiFiConnectionError.WEP_NOT_SUPPORTED:
    showDialog(context, 'WEP security is not supported. Please use WPA/WPA2.');
    break;
  default:
    showDialog(context, 'Connection failed: ${result.errorMessage}');
    break;
}
```

### Backward Compatibility

The original methods still work and now internally use the new error-aware methods:

```dart
// Old method - still works
bool connected = await WiFiForIoTPlugin.connect('MyNetwork', password: 'mypassword');

// New method - provides detailed error information
WiFiConnectionResult result = await WiFiForIoTPlugin.connectWithResult('MyNetwork', password: 'mypassword');
bool connected = result.success; // Same result as old method
```

## Platform-Specific Error Mapping

### Android

The Android implementation maps system errors to our error codes:

- Network suggestion API errors → `NETWORK_SUGGESTION_FAILED`
- Invalid BSSID format → `INVALID_BSSID`
- WEP on Android 10+ → `WEP_NOT_SUPPORTED`
- Network callback timeouts → `NETWORK_UNAVAILABLE`
- Network lost events → `CONNECTION_TIMEOUT`

### iOS

iOS implementation follows similar patterns but may have platform-specific error mappings.

## Migration Guide

To migrate from the old boolean-based methods to the new error-aware methods:

1. Replace `connect()` calls with `connectWithResult()`
2. Replace `findAndConnect()` calls with `findAndConnectWithResult()`
3. Update error handling to use the detailed error information
4. Provide better user feedback based on specific error codes

The old methods are still available for backward compatibility.
