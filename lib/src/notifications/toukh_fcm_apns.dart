import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// iOS APNS token readiness before requesting FCM token.
abstract final class ToukhFcmApns {
  ToukhFcmApns._();

  static const _retryCount = 3;
  static const _retryDelay = Duration(milliseconds: 500);

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  /// Waits briefly for APNS token on iOS so [FirebaseMessaging.getToken] succeeds.
  static Future<void> waitForApnsTokenIfNeeded() async {
    if (!_isIos) return;
    for (var attempt = 0; attempt < _retryCount; attempt++) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return;
      if (attempt < _retryCount - 1) {
        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  /// Returns FCM token after APNS is ready on iOS.
  static Future<String?> getToken() async {
    await waitForApnsTokenIfNeeded();
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
