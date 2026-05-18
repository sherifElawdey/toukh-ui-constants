import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'toukh_notification.dart';
import 'toukh_notification_mapper.dart';
import 'toukh_notification_recipient.dart';
import 'toukh_push_config.dart';

typedef FcmTokenPersister = Future<void> Function(String uid, String token);
typedef NotificationTapHandler = Future<void> Function(ToukhNotification message);

/// Shared FCM + local notifications bootstrap for Toukh apps.
class ToukhPushMessaging {
  ToukhPushMessaging._();

  static final ToukhPushMessaging instance = ToukhPushMessaging._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FcmTokenPersister? _persistToken;
  NotificationTapHandler? _onTap;
  ToukhNotificationRecipient? _recipient;
  bool _initialized = false;

  /// Top-level background handler — register in each app's `main.dart`:
  /// `FirebaseMessaging.onBackgroundMessage(toukhFirebaseMessagingBackgroundHandler);`
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    debugPrint('FCM background: ${message.messageId}');
  }

  Future<void> initialize({
    required FcmTokenPersister persistToken,
    required NotificationTapHandler onTap,
    required ToukhNotificationRecipient recipient,
  }) async {
    if (_initialized) return;
    _persistToken = persistToken;
    _onTap = onTap;
    _recipient = recipient;

    await _local.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/${ToukhPushConfig.androidIcon}'),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _handlePayloadString(payload);
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        ToukhPushConfig.androidChannelId,
        ToukhPushConfig.androidChannelName,
        description: ToukhPushConfig.androidChannelDescription,
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      await _handleRemoteMessage(initial);
    }

    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS) {
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        // Apps should call syncToken(uid) after auth; refresh handled there.
        debugPrint('FCM token refreshed (${_recipient?.name})');
      });
    }

    _initialized = true;
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Future<void> syncToken(String uid) async {
    if (!_initialized || _persistToken == null) return;
    if (kIsWeb) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS APNS pipeline may be deferred in some builds.
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await _persistToken!(uid, token);
        }
      } on FirebaseException catch (e) {
        debugPrint('FCM syncToken iOS deferred: ${e.code}');
      }
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistToken!(uid, token);
      }
    } catch (e, st) {
      debugPrint('FCM syncToken failed: $e\n$st');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    final data = message.data;
    final title = n?.title ?? data['title'] ?? 'Toukh';
    final body = n?.body ?? data['body'] ?? data['description'] ?? '';

    final fcmPayload = _encodeTapPayload(message);
    _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          ToukhPushConfig.androidChannelId,
          ToukhPushConfig.androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: fcmPayload,
    );
  }

  Future<void> _onMessageOpened(RemoteMessage message) async {
    await _handleRemoteMessage(message);
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    if (message.notification != null) {
      data['title'] ??= message.notification!.title;
      data['body'] ??= message.notification!.body;
    }
    final notification = ToukhNotificationMapper.fromFcmData(data);
    if (notification != null && _onTap != null) {
      await _onTap!(notification);
    }
  }

  void _handlePayloadString(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final notification = ToukhNotificationMapper.fromFcmData(map);
      if (notification != null && _onTap != null) {
        _onTap!(notification);
      }
    } catch (e) {
      debugPrint('FCM tap payload parse failed: $e');
    }
  }

  String _encodeTapPayload(RemoteMessage message) {
    final data = Map<String, String>.from(message.data);
    return jsonEncode(data);
  }
}
