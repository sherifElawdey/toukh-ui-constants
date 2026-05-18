/// In-app navigation targets for notification deep links (GoRouter paths).
abstract final class ToukhNotificationRoutes {
  ToukhNotificationRoutes._();

  // Consumer (toukh)
  static const consumerOrders = '/orders';
  static const consumerNotifications = '/notifications';

  // Provider (toukh_provider)
  static const providerOrders = '/orders';
  static const providerNotifications = '/notifications';

  static String providerOrderDetail(String orderId) => '$providerOrders/$orderId';

  // Driver (toukh_delivery)
  static const driverOrders = '/orders';
  static const driverNotifications = '/notifications';

  static String driverOrderDetail(String orderId) =>
      '$driverOrders/detail/${Uri.encodeComponent(orderId)}';
}
