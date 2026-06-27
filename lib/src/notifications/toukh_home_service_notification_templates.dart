import 'toukh_home_service_notification_types.dart';
import 'toukh_notification.dart';
import 'toukh_notification_category.dart';
import 'toukh_notification_routes.dart';

/// Shared templates for home service request notifications.
abstract final class ToukhHomeServiceNotificationTemplates {
  ToukhHomeServiceNotificationTemplates._();

  static const _kCollection = 'homeServiceRequests';
  static const _maxNotePreviewLines = 2;

  static String providerNewRequestNotificationId(String requestId) =>
      'home_service_request_$requestId';

  static String homeServiceRequestsCollection() => _kCollection;

  static ToukhNotificationTemplate buildProviderNewRequestTemplate({
    required Map<String, dynamic> request,
    required String providerId,
    required String requestId,
    String? customerPhotoUrl,
  }) {
    final customerName =
        _string(request['customerName']) ?? _string(request['userName']) ?? 'Customer';
    final categoryTitle = _string(request['categoryTitle']) ?? 'Home service';
    final note = _string(request['note']);
    final description = _formatDescription(categoryTitle: categoryTitle, note: note);
    final imageUrl = _string(request['customerPhotoUrl']) ?? customerPhotoUrl;
    final userId = _string(request['userId']);
    final status = _string(request['status']) ?? 'pending';

    return ToukhNotificationTemplate(
      title: 'New request · $customerName',
      description: description,
      imageUrl: imageUrl,
      type: ToukhHomeServiceNotificationTypes.homeServiceRequestPlaced,
      category: ToukhNotificationCategory.homeService,
      rootRoute: ToukhNotificationRoutes.providerHomeServiceRequestDetail(requestId),
      payload: {
        'requestId': requestId,
        'providerId': providerId,
        'userId': userId,
        'customerName': customerName,
        'categoryTitle': categoryTitle,
        if (note != null) 'note': note,
        'status': status,
      },
    );
  }

  static ToukhNotification notificationFromProviderRequest({
    required String notificationId,
    required Map<String, dynamic> request,
    required String providerId,
    required String requestId,
    String? customerPhotoUrl,
  }) {
    final template = buildProviderNewRequestTemplate(
      request: request,
      providerId: providerId,
      requestId: requestId,
      customerPhotoUrl: customerPhotoUrl,
    );
    return ToukhNotification(
      id: notificationId,
      title: template.title,
      description: template.description,
      imageUrl: template.imageUrl,
      type: template.type,
      category: template.category,
      rootRoute: template.rootRoute,
      payload: template.payload,
    );
  }

  static String _formatDescription({
    required String categoryTitle,
    String? note,
  }) {
    final lines = <String>[categoryTitle];
    if (note != null && note.isNotEmpty) {
      final noteLines = note.split('\n').where((l) => l.trim().isNotEmpty);
      lines.addAll(noteLines.take(_maxNotePreviewLines));
    }
    return lines.join('\n');
  }

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
