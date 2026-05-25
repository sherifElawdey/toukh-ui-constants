import 'cart_line_for_split.dart';
import 'delivery_fee_calculator.dart';
import 'fulfillment_mode.dart';
import 'order_split_plan.dart';
import 'provider_delivery_config.dart';
import 'provider_sub_state.dart';

/// Splits a cart into provider order plans (CASE 1–3).
abstract final class OrderSplittingEngine {
  static OrderSplitPlan plan({
    required List<CartLineForSplit> lines,
    required Map<String, ProviderDeliveryConfig> providerConfigs,
    double platformFeeEgp = 0,
  }) {
    if (lines.isEmpty) {
      return const OrderSplitPlan(
        providerOrders: [],
        aggregatedGroupId: null,
        needsDeliveryTask: false,
        subtotalEgp: 0,
        deliveryFeeEgp: 0,
        totalEgp: 0,
      );
    }

    final byProvider = <String, List<CartLineForSplit>>{};
    for (final line in lines) {
      byProvider.putIfAbsent(line.providerId, () => []).add(line);
    }

    final providerIds = byProvider.keys.toList();
    final storeDeliveryIds = <String>{};
    final courierOnlyIds = <String>{};

    for (final pid in providerIds) {
      final cfg = providerConfigs[pid] ?? ProviderDeliveryConfig(providerId: pid);
      if (cfg.offersDelivery) {
        storeDeliveryIds.add(pid);
      } else {
        courierOnlyIds.add(pid);
      }
    }

    String? aggregatedGroupId;
    final Set<String> aggregatedCourierIds;

    if (providerIds.length == 1) {
      aggregatedCourierIds = {};
    } else if (courierOnlyIds.length >= 2 && courierOnlyIds.length == providerIds.length) {
      // CASE 3b: all providers need external courier — one aggregated group
      aggregatedGroupId = 'agg_${DateTime.now().millisecondsSinceEpoch}';
      aggregatedCourierIds = courierOnlyIds;
    } else {
      // CASE 3 mixed: store-delivery providers independent; courier-only aggregated if 2+
      if (courierOnlyIds.length >= 2) {
        aggregatedGroupId = 'agg_${DateTime.now().millisecondsSinceEpoch}';
        aggregatedCourierIds = courierOnlyIds;
      } else {
        aggregatedCourierIds = {};
      }
    }

    final feeBreakdown = DeliveryFeeCalculator.calculate(
      lines: lines,
      configs: providerConfigs,
      storeDeliveryProviderIds: storeDeliveryIds,
      aggregatedCourierProviderIds: aggregatedCourierIds,
      platformFeeEgp: platformFeeEgp,
    );

    final plans = <SplitProviderOrderPlan>[];
    var subtotal = 0.0;

    for (final entry in byProvider.entries) {
      final pid = entry.key;
      final providerLines = entry.value;
      final orderPrice = providerLines.fold<double>(0, (s, l) => s + l.lineTotal);
      subtotal += orderPrice;

      final cfg = providerConfigs[pid] ?? ProviderDeliveryConfig(providerId: pid);
      final isStore = storeDeliveryIds.contains(pid);
      final isAgg = aggregatedCourierIds.contains(pid);

      FulfillmentMode mode;
      if (providerIds.length == 1) {
        mode = isStore ? FulfillmentMode.store : FulfillmentMode.courier;
      } else {
        mode = isStore ? FulfillmentMode.store : FulfillmentMode.courier;
      }

      plans.add(
        SplitProviderOrderPlan(
          providerId: pid,
          lines: providerLines.map((l) => _lineToOrderItem(l)).toList(),
          fulfillmentMode: mode,
          isAggregated: isAgg,
          orderPriceEgp: orderPrice,
          deliveryFeeEgp: feeBreakdown.perProviderFees[pid] ?? 0,
          providerName: providerLines.first.providerName,
        ),
      );
    }

    final statusMap = {
      for (final p in plans) p.providerId: ProviderSubState.pending,
    };

    final deliveryFee = feeBreakdown.totalDeliveryFeeEgp;
    final needsTask = aggregatedGroupId != null ||
        (providerIds.length == 1 && !storeDeliveryIds.contains(providerIds.first));

    return OrderSplitPlan(
      providerOrders: plans,
      aggregatedGroupId: aggregatedGroupId,
      needsDeliveryTask: needsTask && courierOnlyIds.isNotEmpty || aggregatedGroupId != null,
      subtotalEgp: subtotal,
      deliveryFeeEgp: deliveryFee,
      totalEgp: subtotal + deliveryFee,
      initialProviderStatusMap: statusMap,
    );
  }

  static Map<String, dynamic> _lineToOrderItem(CartLineForSplit line) => {
        'itemId': line.itemId,
        'title': line.title,
        'quantity': line.quantity,
        'unitPrice': line.unitPrice,
        if (line.sizeLabel != null) 'sizeLabel': line.sizeLabel,
        'serviceType': line.serviceType,
      };
}
