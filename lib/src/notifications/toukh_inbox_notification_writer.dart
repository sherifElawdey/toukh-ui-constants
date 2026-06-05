import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'toukh_notification.dart';
import 'toukh_notification_mapper.dart';
import 'toukh_notification_paths.dart';
import 'toukh_notification_recipient.dart';
import 'toukh_order_notification_templates.dart';

/// Client-side inbox delivery (Spark fallback when Cloud Functions are unavailable).
class ToukhInboxNotificationWriter {
  ToukhInboxNotificationWriter(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _orderRef(
    String providerId,
    String orderId,
  ) =>
      _firestore.collection('providers').doc(providerId).collection('orders').doc(orderId);

  CollectionReference<Map<String, dynamic>> _inboxRef(
    ToukhNotificationRecipient recipient,
    String uid,
  ) =>
      _firestore
          .doc(ToukhNotificationPaths.recipientDocPath(
            recipient: recipient,
            uid: uid,
          ))
          .collection(ToukhNotificationPaths.notificationsSubcollection);

  /// Writes a notification doc without idempotency guards.
  Future<String?> deliver({
    required ToukhNotificationRecipient recipient,
    required String recipientUid,
    required ToukhNotificationTemplate template,
  }) async {
    if (recipientUid.trim().isEmpty) return null;
    try {
      final doc = ToukhNotificationMapper.toFirestore(template);
      doc['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _inboxRef(recipient, recipientUid).add(doc);
      return ref.id;
    } catch (e, st) {
      debugPrint('ToukhInboxNotificationWriter.deliver failed: $e\n$st');
      return null;
    }
  }

  /// Idempotent provider new-order inbox row (sets [providerPushSentAt] on order).
  Future<String?> deliverProviderNewOrderIfNeeded({
    required String providerId,
    required String orderId,
    required Map<String, dynamic> order,
    String? customerPhotoUrl,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final orderRef = _orderRef(providerId, orderId);
        final orderSnap = await tx.get(orderRef);
        if (!orderSnap.exists) return null;
        final data = orderSnap.data() ?? {};
        if (data['providerPushSentAt'] != null) return null;

        final template = ToukhOrderNotificationTemplates.buildProviderNewOrderTemplate(
          order: orderSnap.data() ?? order,
          providerId: providerId,
          orderId: orderId,
          customerPhotoUrl: customerPhotoUrl,
        );

        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.provider,
          providerId,
        ).doc();

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);
        tx.set(orderRef, {
          'providerPushSentAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverProviderNewOrderIfNeeded failed: $e\n$st',
      );
      return null;
    }
  }

  /// Idempotent customer order-placed inbox row (sets customerStatusPushAt.placed).
  Future<String?> deliverCustomerOrderPlacedIfNeeded({
    required String customerId,
    required String providerId,
    required String orderId,
    required Map<String, dynamic> order,
    String? providerImageUrl,
  }) async {
    return _deliverCustomerStatusGuarded(
      customerId: customerId,
      providerId: providerId,
      orderId: orderId,
      order: order,
      statusKey: 'placed',
      providerImageUrl: providerImageUrl,
      templateBuilder: (o) => ToukhOrderNotificationTemplates.buildCustomerOrderPlacedTemplate(
        order: o,
        providerId: providerId,
        orderId: orderId,
        providerImageUrl: providerImageUrl,
      ),
    );
  }

  /// Idempotent customer status inbox row (sets customerStatusPushAt.{status}).
  Future<String?> deliverCustomerStatusIfNeeded({
    required String providerId,
    required String orderId,
    Map<String, dynamic>? order,
    String? nextStatus,
    String? providerImageUrl,
  }) async {
    try {
      final orderRef = _orderRef(providerId, orderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) return null;

      final orderData = order ?? orderSnap.data() ?? {};
      final status = nextStatus ?? orderData['status']?.toString();
      if (status == null || status.isEmpty) return null;

      final customerId = ToukhOrderNotificationTemplates.resolveCustomerId(orderData);
      if (customerId == null) return null;

      final template = ToukhOrderNotificationTemplates.buildCustomerStatusTemplate(
        order: orderData,
        providerId: providerId,
        orderId: orderId,
        nextStatus: status,
        providerImageUrl: providerImageUrl,
      );
      if (template == null) return null;

      return _deliverCustomerStatusGuarded(
        customerId: customerId,
        providerId: providerId,
        orderId: orderId,
        order: orderData,
        statusKey: status,
        providerImageUrl: providerImageUrl,
        templateBuilder: (_) => template,
      );
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverCustomerStatusIfNeeded failed: $e\n$st',
      );
      return null;
    }
  }

  Future<String?> _deliverCustomerStatusGuarded({
    required String customerId,
    required String providerId,
    required String orderId,
    required Map<String, dynamic> order,
    required String statusKey,
    required ToukhNotificationTemplate Function(Map<String, dynamic> order)
        templateBuilder,
    String? providerImageUrl,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final orderRef = _orderRef(providerId, orderId);
        final orderSnap = await tx.get(orderRef);
        if (!orderSnap.exists) return null;

        final data = orderSnap.data() ?? order;
        final pushMap = data['customerStatusPushAt'];
        if (pushMap is Map && pushMap[statusKey] != null) return null;

        final template = templateBuilder(data);
        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.customer,
          customerId,
        ).doc();

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);
        tx.set(orderRef, {
          'customerStatusPushAt.$statusKey': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter._deliverCustomerStatusGuarded failed: $e\n$st',
      );
      return null;
    }
  }

  /// Best-effort provider profile image for customer notifications.
  Future<String?> fetchProviderImageUrl(String providerId) async {
    try {
      final snap = await _firestore.collection('providers').doc(providerId).get();
      final data = snap.data();
      if (data == null) return null;
      for (final key in ['brandImageUrl', 'logoUrl', 'imageUrl', 'photoUrl']) {
        final url = data[key];
        if (url is String && url.trim().isNotEmpty) return url.trim();
      }
    } catch (_) {}
    return null;
  }
}
