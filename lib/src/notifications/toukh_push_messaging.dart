import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'toukh_fcm_apns.dart';
import 'toukh_fcm_token_sync.dart';
import 'toukh_notification.dart';
import 'toukh_fcm_data_keys.dart';
import 'toukh_notification_mapper.dart';
import 'toukh_notification_recipient.dart';
import 'toukh_order_notification_types.dart';
import 'toukh_push_config.dart';

typedef FcmTokenPersister = Future<void> Function(String uid, String token);
typedef NotificationTapHandler = Future<void> Function(ToukhNotification message);
typedef ForegroundNotificationHandler = void Function(ToukhNotification message);

/// Shared FCM + local notifications bootstrap for Toukh apps.
class ToukhPushMessaging {
  ToukhPushMessaging._();

  static final ToukhPushMessaging instance = ToukhPushMessaging._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FcmTokenPersister? _persistToken;
  NotificationTapHandler? _onTap;
  ForegroundNotificationHandler? _onForegroundNotification;
  ToukhNotificationRecipient? _recipient;
  FirebaseFirestore? _firestore;
  bool _initialized = false;

  /// Top-level background handler — register in each app's `main.dart`:
  /// `FirebaseMessaging.onBackgroundMessage(toukhFirebaseMessagingBackgroundHandler);`
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    if (kIsWeb) return;
    final n = message.notification;
    if (n == null) {
      debugPrint('FCM background (data-only): ${message.messageId}');
      return;
    }
    final plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: android, iOS: DarwinInitializationSettings()),
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        ToukhPushConfig.androidChannelId,
        ToukhPushConfig.androidChannelName,
        description: ToukhPushConfig.androidChannelDescription,
        importance: Importance.high,
      );
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    await plugin.show(
      message.hashCode,
      n.title ?? message.data['title'] ?? 'Toukh',
      n.body ?? message.data['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          ToukhPushConfig.androidChannelId,
          ToukhPushConfig.androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> initialize({
    required NotificationTapHandler onTap,
    required ToukhNotificationRecipient recipient,
    required FirebaseFirestore firestore,
    FcmTokenPersister? persistToken,
    ForegroundNotificationHandler? onForegroundNotification,
  }) async {
    if (_initialized) return;
    _persistToken = persistToken;
    _onTap = onTap;
    _onForegroundNotification = onForegroundNotification;
    _recipient = recipient;
    _firestore = firestore;

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
    try {
      final initial = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 3));
      if (initial != null) {
        await _handleRemoteMessage(initial);
      }
    } on TimeoutException {
      debugPrint('FCM getInitialMessage timed out; skipping cold-start tap.');
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

  Future<String?> getToken() => ToukhFcmApns.getToken();

  Future<void> syncToken(
    String uid, {
    List<String> existingFcmTokens = const [],
  }) async {
    if (!_initialized) return;
    if (kIsWeb) return;

    Future<void> syncWithRegistry() async {
      final firestore = _firestore;
      final recipient = _recipient;
      if (firestore == null || recipient == null) return;
      await ToukhFcmTokenSync.syncIfNeeded(
        uid: uid,
        existingFcmTokens: existingFcmTokens,
        firestore: firestore,
        recipient: recipient,
        getCurrentToken: getToken,
      );
    }

    if (_firestore != null && _recipient != null) {
      Future<void> syncLive() => ToukhFcmTokenSync.syncOnAppOpen(
            uid: uid,
            firestore: _firestore!,
            recipient: _recipient!,
            getCurrentToken: getToken,
          );
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          await syncLive();
        } on FirebaseException catch (e) {
          debugPrint('FCM syncToken iOS deferred: ${e.code}');
        }
        return;
      }
      await syncLive();
      return;
    }

    final persist = _persistToken;
    if (persist == null) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final token = await ToukhFcmApns.getToken();
        if (token != null && token.isNotEmpty) {
          await persist(uid, token);
        }
      } on FirebaseException catch (e) {
        debugPrint('FCM syncToken iOS deferred: ${e.code}');
      }
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await persist(uid, token);
      }
    } catch (e, st) {
      debugPrint('FCM syncToken failed: $e\n$st');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    unawaited(_showForegroundNotification(message));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final n = message.notification;
    final data = message.data;
    final title = n?.title ?? data['title'] ?? 'Toukh';
    final body = n?.body ?? data['body'] ?? data['description'] ?? '';

    final parsed = _notificationFromMessage(message);
    final handler = _onForegroundNotification;
    final isOrderPlaced = parsed?.type == ToukhOrderNotificationTypes.orderPlaced;
    if (handler != null && parsed != null && isOrderPlaced) {
      handler(parsed);
      return;
    }

    final imageUrl = _resolveImageUrl(message);
    final fcmPayload = _encodeTapPayload(message);
    final details = await _buildForegroundNotificationDetails(imageUrl);

    await _local.show(
      message.hashCode,
      title,
      body,
      details,
      payload: fcmPayload,
    );
  }

  ToukhNotification? _notificationFromMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    if (message.notification != null) {
      data['title'] ??= message.notification!.title;
      data['body'] ??= message.notification!.body;
    }
    var notification = ToukhNotificationMapper.fromFcmData(data);
    if (notification != null) return notification;

    final orderId = data[ToukhFcmDataKeys.orderId]?.toString();
    if (orderId == null || orderId.isEmpty) return null;
    return ToukhNotification(
      id: data[ToukhFcmDataKeys.notificationId]?.toString() ?? orderId,
      title: data['title']?.toString() ?? 'Toukh',
      description:
          data['body']?.toString() ?? data['description']?.toString() ?? '',
      imageUrl: data[ToukhFcmDataKeys.imageUrl]?.toString(),
      rootRoute: data[ToukhFcmDataKeys.rootRoute]?.toString() ?? '',
      payload: _decodePayloadJson(data[ToukhFcmDataKeys.payloadJson]),
      type: data[ToukhFcmDataKeys.type]?.toString(),
      orderId: orderId,
      category: data[ToukhFcmDataKeys.category]?.toString() ?? 'order',
    );
  }

  Map<String, dynamic> _decodePayloadJson(dynamic raw) {
    if (raw is! String || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  String? _resolveImageUrl(RemoteMessage message) {
    final n = message.notification;
    final fromData = message.data['imageUrl'];
    if (fromData != null && fromData.trim().isNotEmpty) return fromData.trim();
    final android = n?.android?.imageUrl;
    if (android != null && android.trim().isNotEmpty) return android.trim();
    final apple = n?.apple?.imageUrl;
    if (apple != null && apple.trim().isNotEmpty) return apple.trim();
    return null;
  }

  Future<NotificationDetails> _buildForegroundNotificationDetails(
    String? imageUrl,
  ) async {
    if (imageUrl == null || imageUrl.isEmpty || kIsWeb) {
      return _defaultNotificationDetails();
    }

    final imageFile = await _downloadNotificationImage(imageUrl);
    if (imageFile == null) return _defaultNotificationDetails();

    if (defaultTargetPlatform == TargetPlatform.android) {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          ToukhPushConfig.androidChannelId,
          ToukhPushConfig.androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(imageFile.path),
            hideExpandedLargeIcon: true,
          ),
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return NotificationDetails(
        iOS: DarwinNotificationDetails(
          attachments: [DarwinNotificationAttachment(imageFile.path)],
        ),
      );
    }

    return _defaultNotificationDetails();
  }

  Future<File?> _downloadNotificationImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final file = File(
        '${Directory.systemTemp.path}/toukh_fcm_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('FCM foreground image download failed: $e');
      return null;
    }
  }

  NotificationDetails _defaultNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        ToukhPushConfig.androidChannelId,
        ToukhPushConfig.androidChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
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
