import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

const platform = MethodChannel('com.example.doctors_path_academy/security');

Future<bool> isDeveloperModeEnabled() async {
  if (Platform.isAndroid) {
    try {
      return await platform.invokeMethod('isDeveloperModeEnabled');
    } on PlatformException {
      return false;
    }
  }
  return false;
}

Future<bool> isUsbDebuggingEnabled() async {
  if (Platform.isAndroid) {
    try {
      return await platform.invokeMethod('isUsbDebuggingEnabled');
    } on PlatformException {
      return false;
    }
  }
  return false;
}

Future<String?> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor;
  }
  return null;
}

// =============================================
// ======== SECURITY CHECKS
// =============================================

/// Checks for hardware signs of an emulator.
Future<bool> isEmulator() async {
  if (Platform.isAndroid) {
    try {
      return await platform.invokeMethod('isEmulator');
    } on PlatformException {
      return false;
    }
  }
  return false;
}

/// Checks if a valid Egyptian SIM card is present and ready.
Future<bool> isEgyptianSimPresent() async {
  if (Platform.isAndroid) {
    try {
      return await platform.invokeMethod('isEgyptianSimPresent');
    } on PlatformException {
      return false;
    }
  }
  return true; 
}

/// Fetches battery level and charging status from native code.
Future<Map<String, dynamic>> getBatteryStatus() async {
  if (Platform.isAndroid) {
    try {
      final status = await platform.invokeMethod('getBatteryStatus');
      // The returned value is Map<dynamic, dynamic>, so we cast it.
      return Map<String, dynamic>.from(status);
    } on PlatformException {
      // Return a default "safe" status if the method fails.
      return {'level': 100, 'isCharging': true};
    }
  }
  // Default for non-Android platforms.
  return {'level': 100, 'isCharging': true};
}
