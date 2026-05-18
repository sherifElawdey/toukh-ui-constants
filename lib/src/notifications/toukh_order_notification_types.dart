/// Server/client notification type strings for order lifecycle events.
abstract final class ToukhOrderNotificationTypes {
  ToukhOrderNotificationTypes._();

  static const orderPlaced = 'order_placed';
  static const orderAccepted = 'order_accepted';
  static const orderCancelled = 'order_cancelled';
  static const courierRequested = 'courier_requested';
  static const courierAssigned = 'courier_assigned';
  static const readyForPickup = 'ready_for_pickup';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'order_delivered';
  static const courierLate = 'courier_late';
  static const deliveryRequest = 'delivery_request';
}
