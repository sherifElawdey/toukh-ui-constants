import 'package:toukh_ui/src/orders/provider_order_slice.dart';
import 'package:toukh_ui/src/orders/provider_order_slice_line_item.dart';

/// Display model for a horizontal order item card.
class OrderItemCardData {
  const OrderItemCardData({
    required this.title,
    required this.quantity,
    required this.lineTotalEgp,
    this.unitPriceEgp = 0,
    this.imageUrl,
  });

  final String title;
  final int quantity;
  final double lineTotalEgp;
  final double unitPriceEgp;
  final String? imageUrl;

  double get effectiveUnitPriceEgp {
    if (unitPriceEgp > 0) return unitPriceEgp;
    if (quantity > 0 && lineTotalEgp > 0) return lineTotalEgp / quantity;
    return 0;
  }

  factory OrderItemCardData.fromSliceLine(ProviderOrderSliceLineItem item) {
    return OrderItemCardData(
      title: item.name,
      quantity: item.quantity,
      lineTotalEgp: item.lineTotalEgp,
      unitPriceEgp: item.effectiveUnitPriceEgp,
      imageUrl: item.imageUrl,
    );
  }
}

/// Fee rows for master or single-slice breakdowns.
class OrderFeeBreakdownData {
  const OrderFeeBreakdownData({
    required this.itemsSubtotalEgp,
    required this.serviceFeeEgp,
    required this.deliveryFeeEgp,
    required this.totalEgp,
  });

  final double itemsSubtotalEgp;
  final double serviceFeeEgp;
  final double deliveryFeeEgp;
  final double totalEgp;

  factory OrderFeeBreakdownData.fromSlice(ProviderOrderSlice slice) {
    return OrderFeeBreakdownData(
      itemsSubtotalEgp: slice.orderPriceEgp,
      serviceFeeEgp: slice.serviceFeeEgp,
      deliveryFeeEgp: slice.deliveryFeeEgp,
      totalEgp: slice.totalEgp > 0
          ? slice.totalEgp
          : slice.orderPriceEgp + slice.deliveryFeeEgp + slice.serviceFeeEgp,
    );
  }

  /// For legacy slices missing [ProviderOrderSlice.serviceFeeEgp], derive
  /// pro-rata share from master fee and master subtotal.
  static double prorateServiceFee({
    required double masterServiceFeeEgp,
    required double masterSubtotalEgp,
    required double sliceOrderPriceEgp,
  }) {
    if (masterServiceFeeEgp <= 0 || masterSubtotalEgp <= 0) return 0;
    return double.parse(
      (masterServiceFeeEgp * (sliceOrderPriceEgp / masterSubtotalEgp))
          .toStringAsFixed(2),
    );
  }
}

/// One step in an order/request track.
class OrderTrackStepData {
  const OrderTrackStepData({
    required this.id,
    required this.label,
    required this.icon,
    this.at,
    this.isActive = false,
    this.isDone = false,
    this.subSteps = const [],
  });

  final String id;
  final String label;
  final Object icon; // IconData from apps
  final DateTime? at;
  final bool isActive;
  final bool isDone;
  final List<OrderTrackSubStepData> subSteps;
}

class OrderTrackSubStepData {
  const OrderTrackSubStepData({
    required this.label,
    this.at,
    this.isDone = false,
  });

  final String label;
  final DateTime? at;
  final bool isDone;
}
