import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'toukh_notification_recipient.dart';
import 'toukh_push_messaging.dart';

/// Merges and persists FCM device tokens on user/provider/driver profiles.
abstract final class ToukhFcmTokenSync {
  ToukhFcmTokenSync._();

  static const int maxFcmTokens = 5;

  /// Returns [existing] when [newToken] is already present; otherwise appends
  /// [newToken] and drops the oldest entries until length is at most [maxFcmTokens].
  static List<String> mergeFcmToken(List<String> existing, String newToken) {
    final list = existing.where((t) => t.isNotEmpty).toList();
    if (list.contains(newToken)) return list;
    final updated = [...list, newToken];
    while (updated.length > maxFcmTokens) {
      updated.removeAt(0);
    }
    return updated;
  }

  /// Registers the current device FCM token on the profile when it is not
  /// already in [existingFcmTokens].
  static Future<void> syncIfNeeded({
    required String uid,
    required List<String> existingFcmTokens,
    required FirebaseFirestore firestore,
    required ToukhNotificationRecipient recipient,
    Future<String?> Function()? getCurrentToken,
  }) async {
    try {
      final token = await (getCurrentToken ?? ToukhPushMessaging.instance.getToken)();
      if (token == null || token.isEmpty) return;
      if (existingFcmTokens.contains(token)) return;

      final merged = mergeFcmToken(existingFcmTokens, token);
      await firestore.collection(recipient.collectionName).doc(uid).set(
        {
          'fcmTokens': merged,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('ToukhFcmTokenSync.syncIfNeeded failed: $e\n$st');
    }
  }
}
