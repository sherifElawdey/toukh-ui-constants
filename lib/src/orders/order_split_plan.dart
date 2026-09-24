import 'package:equatable/equatable.dart';

import 'fulfillment_mode.dart';
import 'provider_sub_state.dart';

class SplitProviderOrderPlan extends Equatable {
  const SplitProviderOrderPlan({
    required this.providerId,
    required this.lines,
    required this.fulfillmentMode,
    required this.isAggregated,
    required this.orderPriceEgp,
    required this.deliveryFeeEgp,
    this.serviceFeeEgp = 0,
    this.providerName,
  });

  final String providerId;
  final List<Map<String, dynamic>> lines;
  final FulfillmentMode fulfillmentMode;
  final bool isAggregated;
  final double orderPriceEgp;
  final double deliveryFeeEgp;
  final double serviceFeeEgp;
  final String? providerName;

  @override
  List<Object?> get props => [
        providerId,
        lines,
        fulfillmentMode,
        isAggregated,
        orderPriceEgp,
        deliveryFeeEgp,
        serviceFeeEgp,
      ];
}

class OrderSplitPlan extends Equatable {
  const OrderSplitPlan({
    required this.providerOrders,
    required this.aggregatedGroupId,
    required this.needsDeliveryTask,
    required this.subtotalEgp,
    required this.deliveryFeeEgp,
    required this.totalEgp,
    this.serviceFeeEgp = 0,
    this.initialProviderStatusMap = const {},
  });

  final List<SplitProviderOrderPlan> providerOrders;
  final String? aggregatedGroupId;
  final bool needsDeliveryTask;
  final double subtotalEgp;
  final double deliveryFeeEgp;
  final double totalEgp;
  final double serviceFeeEgp;
  final Map<String, ProviderSubState> initialProviderStatusMap;

  @override
  List<Object?> get props => [
        providerOrders,
        aggregatedGroupId,
        needsDeliveryTask,
        subtotalEgp,
        deliveryFeeEgp,
        totalEgp,
        serviceFeeEgp,
        initialProviderStatusMap,
      ];
}
