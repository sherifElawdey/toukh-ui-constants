import 'toukh_notification.dart';
import 'toukh_notification_category.dart';
import 'toukh_notification_routes.dart';
import 'toukh_order_notification_types.dart';

/// Statuses that notify the order owner (customer).
abstract final class ToukhCustomerNotifyStatuses {
  ToukhCustomerNotifyStatuses._();

  static const all = {
    'accepted',
    'preparing',
    'cancelled',
    'courier_requested',
    'courier_assigned',
    'ready_for_pickup',
    'out_for_delivery',
    'picked_up',
    'delivered',
    'completed',
  };
}

abstract final class ToukhOrderNotificationTemplates {
  ToukhOrderNotificationTemplates._();

  static const _maxBodyLines = 3;

  static String? resolveCustomerId(Map<String, dynamic> order) {
    final id = order['customerId'] ?? order['clientId'];
    if (id is! String || id.trim().isEmpty) return null;
    return id.trim();
  }

  static ToukhNotificationTemplate buildProviderNewOrderTemplate({
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    String? customerPhotoUrl,
  }) {
    final customerName =
        _string(order['customerName']) ?? _string(order['clientName']) ?? 'Customer';
    final totals = _orderTotalsAndItems(order);
    final itemsBlock = _formatOrderLinesBlock(
      orderPrice: totals.orderPrice,
      deliveryPrice: totals.deliveryPrice,
      totalEgp: totals.totalEgp,
      mappedItems: totals.mappedItems,
    );

    final imageUrl = _string(order['customerPhotoUrl']) ?? customerPhotoUrl;

    return ToukhNotificationTemplate(
      title: 'New order · $customerName',
      description: itemsBlock,
      imageUrl: imageUrl,
      type: ToukhOrderNotificationTypes.orderPlaced,
      orderId: orderId,
      category: ToukhNotificationCategory.order,
      rootRoute: ToukhNotificationRoutes.providerOrderDetail(orderId),
      payload: {
        'orderId': orderId,
        'providerId': providerId,
        'masterOrderId': order['masterOrderId'],
        'customerId': resolveCustomerId(order),
        'customerName': customerName,
        'orderPriceEgp': totals.orderPrice,
        'deliveryPriceEgp': totals.deliveryPrice,
        'totalEgp': totals.totalEgp,
        'items': totals.mappedItems,
        'orderStatus': 'placed',
      },
    );
  }

  static ToukhNotificationTemplate buildCustomerOrderPlacedTemplate({
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    String? providerImageUrl,
  }) {
    final masterOrderId = _string(order['masterOrderId']);
    final customerRoute = masterOrderId != null
        ? ToukhNotificationRoutes.consumerOrderDetail(masterOrderId)
        : ToukhNotificationRoutes.consumerOrders;
    final totals = _orderTotalsAndItems(order);
    final itemsBlock = _formatOrderLinesBlock(
      orderPrice: totals.orderPrice,
      deliveryPrice: totals.deliveryPrice,
      totalEgp: totals.totalEgp,
      mappedItems: totals.mappedItems,
    );

    return ToukhNotificationTemplate(
      title: 'Order placed',
      description: _formatDescriptionWithHeadline(
        'Your order was sent to the store.',
        itemsBlock,
      ),
      imageUrl: providerImageUrl,
      type: ToukhOrderNotificationTypes.orderPlaced,
      orderId: orderId,
      category: ToukhNotificationCategory.order,
      rootRoute: customerRoute,
      payload: {
        'orderId': orderId,
        'providerId': providerId,
        'masterOrderId': masterOrderId,
        'orderStatus': 'placed',
        'orderPriceEgp': totals.orderPrice,
        'deliveryPriceEgp': totals.deliveryPrice,
        'totalEgp': totals.totalEgp,
        'items': totals.mappedItems,
      },
    );
  }

  static ToukhNotificationTemplate? buildCustomerStatusTemplate({
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    required String nextStatus,
    String? providerImageUrl,
  }) {
    if (!ToukhCustomerNotifyStatuses.all.contains(nextStatus)) return null;

    final copy = _statusCopy[nextStatus];
    if (copy == null) return null;

    final masterOrderId = _string(order['masterOrderId']);
    final customerRoute = masterOrderId != null
        ? ToukhNotificationRoutes.consumerOrderDetail(masterOrderId)
        : ToukhNotificationRoutes.consumerOrders;
    final totals = _orderTotalsAndItems(order);
    final itemsBlock = _formatOrderLinesBlock(
      orderPrice: totals.orderPrice,
      deliveryPrice: totals.deliveryPrice,
      totalEgp: totals.totalEgp,
      mappedItems: totals.mappedItems,
    );

    final payload = <String, dynamic>{
      'orderId': orderId,
      'providerId': providerId,
      'masterOrderId': masterOrderId,
      'orderStatus': nextStatus,
      'orderPriceEgp': totals.orderPrice,
      'deliveryPriceEgp': totals.deliveryPrice,
      'totalEgp': totals.totalEgp,
      'items': totals.mappedItems,
    };
    if (nextStatus == 'courier_assigned') {
      final driverId = _string(order['driverId']);
      if (driverId != null) payload['driverId'] = driverId;
    }

    return ToukhNotificationTemplate(
      title: copy.title,
      description: _formatDescriptionWithHeadline(copy.headline, itemsBlock),
      imageUrl: providerImageUrl,
      type: copy.type,
      orderId: orderId,
      category: ToukhNotificationCategory.order,
      rootRoute: customerRoute,
      payload: payload,
    );
  }

  static ToukhNotification notificationFromProviderOrder({
    required String notificationId,
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    String? customerPhotoUrl,
  }) {
    final template = buildProviderNewOrderTemplate(
      order: order,
      providerId: providerId,
      orderId: orderId,
      customerPhotoUrl: customerPhotoUrl,
    );
    return ToukhNotification(
      id: notificationId,
      title: template.title,
      description: template.description,
      imageUrl: template.imageUrl,
      type: template.type,
      orderId: template.orderId,
      category: template.category,
      rootRoute: template.rootRoute,
      payload: template.payload,
    );
  }

  static const _statusCopy = {
    'accepted': _StatusCopy(
      title: 'Order approved',
      headline: 'The store accepted your order and is preparing it.',
      type: ToukhOrderNotificationTypes.orderAccepted,
    ),
    'preparing': _StatusCopy(
      title: 'Order approved',
      headline: 'The store accepted your order and is preparing it.',
      type: ToukhOrderNotificationTypes.orderAccepted,
    ),
    'cancelled': _StatusCopy(
      title: 'Order cancelled',
      headline: 'The store could not fulfill your order.',
      type: ToukhOrderNotificationTypes.orderCancelled,
    ),
    'courier_requested': _StatusCopy(
      title: 'Delivery requested',
      headline: 'The store is arranging a courier for your order.',
      type: ToukhOrderNotificationTypes.courierRequested,
    ),
    'courier_assigned': _StatusCopy(
      title: 'Courier assigned',
      headline: 'A courier is on the way to pick up your order.',
      type: ToukhOrderNotificationTypes.courierAssigned,
    ),
    'ready_for_pickup': _StatusCopy(
      title: 'Ready for pickup',
      headline: 'Your order is ready and waiting for the courier.',
      type: ToukhOrderNotificationTypes.readyForPickup,
    ),
    'out_for_delivery': _StatusCopy(
      title: 'On the way',
      headline: 'Your order is out for delivery.',
      type: ToukhOrderNotificationTypes.outForDelivery,
    ),
    'picked_up': _StatusCopy(
      title: 'Order picked up',
      headline: 'Your order was picked up and is heading your way.',
      type: ToukhOrderNotificationTypes.pickupCompleted,
    ),
    'delivered': _StatusCopy(
      title: 'Delivered',
      headline: 'Your order has been delivered. Enjoy!',
      type: ToukhOrderNotificationTypes.delivered,
    ),
    'completed': _StatusCopy(
      title: 'Delivered',
      headline: 'Your order has been completed.',
      type: ToukhOrderNotificationTypes.delivered,
    ),
  };

  static _OrderTotals _orderTotalsAndItems(Map<String, dynamic> order) {
    final orderPrice = _toNumber(order['orderPrice']);
    final deliveryPrice = _toNumber(order['deliveryPrice']);
    final totalEgp =
        _toNumber(order['totalEgp']) != 0 ? _toNumber(order['totalEgp']) : orderPrice + deliveryPrice;
    final itemsRaw = order['items'];
    final items = itemsRaw is List ? itemsRaw : const [];
    final mappedItems = items
        .whereType<Map>()
        .map((e) => _mapOrderItem(Map<String, dynamic>.from(e)))
        .toList();
    return _OrderTotals(
      orderPrice: orderPrice,
      deliveryPrice: deliveryPrice,
      totalEgp: totalEgp,
      mappedItems: mappedItems,
    );
  }

  static Map<String, dynamic> _mapOrderItem(Map<String, dynamic> item) {
    final name = _string(item['title']) ??
        _string(item['name']) ??
        _string(item['itemName']) ??
        'Item';
    final quantity = (_toInt(item['quantity']) ?? 1).clamp(1, 999999);
    final unitPrice = _toNumber(item['unitPrice']);
    final lineTotal = _toNumber(item['lineTotalEgp']) != 0
        ? _toNumber(item['lineTotalEgp'])
        : _toNumber(item['lineTotal']) != 0
            ? _toNumber(item['lineTotal'])
            : _toNumber(item['priceEgp']) != 0
                ? _toNumber(item['priceEgp'])
                : unitPrice * quantity;
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotalEgp': lineTotal,
    };
  }

  static String _formatOrderLinesBlock({
    required double orderPrice,
    required double deliveryPrice,
    required double totalEgp,
    required List<Map<String, dynamic>> mappedItems,
  }) {
    final lines = mappedItems.map((i) {
      final qty = i['quantity'] as int? ?? 1;
      final name = i['name'] as String? ?? 'Item';
      final lineTotal = (i['lineTotalEgp'] as num?)?.toDouble() ?? 0;
      return '$qty× $name — ${lineTotal.round()} EGP';
    }).toList();

    final shown = lines.take(_maxBodyLines).toList();
    if (lines.length > _maxBodyLines) {
      shown.add('+${lines.length - _maxBodyLines} more');
    }
    if (deliveryPrice > 0) {
      shown.add('Delivery: ${deliveryPrice.round()} EGP');
    }
    shown.add('Total: ${totalEgp.round()} EGP');
    return shown.join('\n');
  }

  static String _formatDescriptionWithHeadline(String headline, String itemsBlock) {
    if (itemsBlock.isEmpty) return headline;
    return '$headline\n$itemsBlock';
  }

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static double _toNumber(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) {
      return double.tryParse(v.trim()) ?? 0;
    }
    return 0;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }
}

class _StatusCopy {
  const _StatusCopy({
    required this.title,
    required this.headline,
    required this.type,
  });

  final String title;
  final String headline;
  final String type;
}

class _OrderTotals {
  const _OrderTotals({
    required this.orderPrice,
    required this.deliveryPrice,
    required this.totalEgp,
    required this.mappedItems,
  });

  final double orderPrice;
  final double deliveryPrice;
  final double totalEgp;
  final List<Map<String, dynamic>> mappedItems;
}
