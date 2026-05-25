/// Firestore collection paths for the order orchestration layer.
abstract final class ToukhOrderPaths {
  ToukhOrderPaths._();

  static const masterOrders = 'masterOrders';
  static const deliveryTasks = 'deliveryTasks';
  static const deliveryRequests = 'deliveryRequests';
  static const orderTimelines = 'orderTimelines';
  static const timelineEventsSubcollection = 'events';

  static String masterOrder(String id) => '$masterOrders/$id';

  static String providerOrders(String providerId) => 'providers/$providerId/orders';

  static String providerOrder(String providerId, String orderId) =>
      '${providerOrders(providerId)}/$orderId';

  static String deliveryTask(String id) => '$deliveryTasks/$id';

  static String timelineEvents(String timelineId) =>
      '$orderTimelines/$timelineId/$timelineEventsSubcollection';

  static String userOrderSummary(String uid, String summaryId) =>
      'users/$uid/orders/$summaryId';
}
