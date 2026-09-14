import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

/// iOS APNS token readiness before requesting FCM token.
abstract final class ToukhFcmApns {
  ToukhFcmApns._();

  /// Longer than before: APNS often arrives after the first 1–2s on cold start.
  static const _retryCount = 12;
  static const _retryDelay = Duration(milliseconds: 750);

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  /// Waits for APNS token on iOS so [FirebaseMessaging.getToken] succeeds.
  static Future<bool> waitForApnsTokenIfNeeded() async {
    if (!_isIos) return true;
    for (var attempt = 0; attempt < _retryCount; attempt++) {
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          if (attempt > 0) {
            debugPrint('FCM APNS ready after ${attempt + 1} attempt(s)');
          }
          return true;
        }
      } catch (e) {
        debugPrint('FCM getAPNSToken attempt ${attempt + 1}: $e');
      }
      if (attempt < _retryCount - 1) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    debugPrint(
      'FCM APNS token missing after $_retryCount attempts '
      '(simulator or Push capability / permission issue?)',
    );
    return false;
  }

  /// Returns FCM token after APNS is ready on iOS. Retries [getToken] briefly.
  static Future<String?> getToken() async {
    final apnsOk = await waitForApnsTokenIfNeeded();
    if (_isIos && !apnsOk) {
      // Still try once — some runtimes recover without a readable APNS token.
      debugPrint('FCM getToken: proceeding without confirmed APNS');
    }
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          if (attempt > 0) {
            debugPrint('FCM getToken ok after ${attempt + 1} attempt(s)');
          }
          return token;
        }
        debugPrint('FCM getToken returned null (attempt ${attempt + 1})');
      } catch (e) {
        debugPrint('FCM getToken error (attempt ${attempt + 1}): $e');
      }
      if (attempt < 3) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    return null;
  }
}
