import 'cart_line_for_split.dart';
import 'delivery_fee_calculator.dart';
import 'fulfillment_mode.dart';
import 'order_split_plan.dart';
import 'provider_delivery_config.dart';
import 'provider_sub_state.dart';

/// Splits a cart into provider order plans (CASE 1–3).
abstract final class OrderSplittingEngine {
  static const exploreServiceType = 'explore';
  static const systemProviderId = 'system';

  static bool isExploreLine(CartLineForSplit line) =>
      line.serviceType == exploreServiceType;

  static OrderSplitPlan plan({
    required List<CartLineForSplit> lines,
    required Map<String, ProviderDeliveryConfig> providerConfigs,
    double platformFeeEgp = 0,
    double serviceFeeEgp = 0,
    double? customerLat,
    double? customerLng,
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

    final exploreLines = lines.where(isExploreLine).toList();
    final deliverableLines = lines.where((l) => !isExploreLine(l)).toList();

    final deliverablePlan = deliverableLines.isEmpty
        ? const OrderSplitPlan(
            providerOrders: [],
            aggregatedGroupId: null,
            needsDeliveryTask: false,
            subtotalEgp: 0,
            deliveryFeeEgp: 0,
            totalEgp: 0,
          )
        : _planDeliverable(
            deliverableLines,
            providerConfigs,
            platformFeeEgp,
            serviceFeeEgp: serviceFeeEgp,
            customerLat: customerLat,
            customerLng: customerLng,
          );

    final explorePlans = _planExplore(exploreLines);
    final exploreSubtotal =
        explorePlans.fold<double>(0, (sum, p) => sum + p.orderPriceEgp);

    final statusMap = {
      ...deliverablePlan.initialProviderStatusMap,
      for (final p in explorePlans) p.providerId: ProviderSubState.pending,
    };

    final combinedSubtotal = deliverablePlan.subtotalEgp + exploreSubtotal;
    // Explore lines share remaining service fee pro-rata after deliverable.
    final deliverableService = deliverablePlan.serviceFeeEgp;
    final exploreService =
        (serviceFeeEgp - deliverableService).clamp(0.0, serviceFeeEgp);
    final exploreWithFees = _applyServiceFeeShares(
      explorePlans,
      exploreService,
      exploreSubtotal,
    );

    return OrderSplitPlan(
      providerOrders: [
        ...deliverablePlan.providerOrders,
        ...exploreWithFees,
      ],
      aggregatedGroupId: deliverablePlan.aggregatedGroupId,
      needsDeliveryTask: deliverablePlan.needsDeliveryTask ||
          explorePlans.any((p) => p.fulfillmentMode == FulfillmentMode.courier),
      subtotalEgp: combinedSubtotal,
      deliveryFeeEgp: deliverablePlan.deliveryFeeEgp,
      serviceFeeEgp: serviceFeeEgp,
      totalEgp: combinedSubtotal +
          deliverablePlan.deliveryFeeEgp +
          serviceFeeEgp,
      initialProviderStatusMap: statusMap,
    );
  }

  static OrderSplitPlan _planDeliverable(
    List<CartLineForSplit> lines,
    Map<String, ProviderDeliveryConfig> providerConfigs,
    double platformFeeEgp, {
    double serviceFeeEgp = 0,
    double? customerLat,
    double? customerLng,
  }) {
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
    } else if (courierOnlyIds.length >= 2 &&
        courierOnlyIds.length == providerIds.length) {
      aggregatedGroupId = 'agg_${DateTime.now().millisecondsSinceEpoch}';
      aggregatedCourierIds = courierOnlyIds;
    } else {
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
      customerLat: customerLat,
      customerLng: customerLng,
    );

    final plans = <SplitProviderOrderPlan>[];
    var subtotal = 0.0;

    for (final entry in byProvider.entries) {
      final pid = entry.key;
      final providerLines = entry.value;
      final orderPrice = providerLines.fold<double>(0, (s, l) => s + l.lineTotal);
      subtotal += orderPrice;

      final isStore = storeDeliveryIds.contains(pid);

      plans.add(
        SplitProviderOrderPlan(
          providerId: pid,
          lines: providerLines.map(_lineToOrderItem).toList(),
          fulfillmentMode: isStore ? FulfillmentMode.store : FulfillmentMode.courier,
          isAggregated: aggregatedCourierIds.contains(pid),
          orderPriceEgp: orderPrice,
          deliveryFeeEgp: feeBreakdown.perProviderFees[pid] ?? 0,
          providerName: providerLines.first.providerName,
        ),
      );
    }

    final withFees = _applyServiceFeeShares(plans, serviceFeeEgp, subtotal);

    final statusMap = {
      for (final p in withFees) p.providerId: ProviderSubState.pending,
    };

    final deliveryFee = feeBreakdown.totalDeliveryFeeEgp;
    final needsTask = aggregatedGroupId != null ||
        (providerIds.length == 1 && !storeDeliveryIds.contains(providerIds.first));

    return OrderSplitPlan(
      providerOrders: withFees,
      aggregatedGroupId: aggregatedGroupId,
      needsDeliveryTask:
          needsTask && courierOnlyIds.isNotEmpty || aggregatedGroupId != null,
      subtotalEgp: subtotal,
      deliveryFeeEgp: deliveryFee,
      serviceFeeEgp: serviceFeeEgp,
      totalEgp: subtotal + deliveryFee + serviceFeeEgp,
      initialProviderStatusMap: statusMap,
    );
  }

  /// Distribute [serviceFeeEgp] pro-rata by [orderPriceEgp]; remainder on last.
  static List<SplitProviderOrderPlan> _applyServiceFeeShares(
    List<SplitProviderOrderPlan> plans,
    double serviceFeeEgp,
    double subtotal,
  ) {
    if (plans.isEmpty || serviceFeeEgp <= 0 || subtotal <= 0) return plans;
    final shares = <double>[];
    var assigned = 0.0;
    for (var i = 0; i < plans.length; i++) {
      if (i == plans.length - 1) {
        shares.add(double.parse((serviceFeeEgp - assigned).toStringAsFixed(2)));
      } else {
        final share = double.parse(
          (serviceFeeEgp * (plans[i].orderPriceEgp / subtotal))
              .toStringAsFixed(2),
        );
        shares.add(share);
        assigned += share;
      }
    }
    return [
      for (var i = 0; i < plans.length; i++)
        SplitProviderOrderPlan(
          providerId: plans[i].providerId,
          lines: plans[i].lines,
          fulfillmentMode: plans[i].fulfillmentMode,
          isAggregated: plans[i].isAggregated,
          orderPriceEgp: plans[i].orderPriceEgp,
          deliveryFeeEgp: plans[i].deliveryFeeEgp,
          serviceFeeEgp: shares[i],
          providerName: plans[i].providerName,
        ),
    ];
  }

  static List<SplitProviderOrderPlan> _planExplore(List<CartLineForSplit> lines) {
    if (lines.isEmpty) return const [];

    final byProvider = <String, List<CartLineForSplit>>{};
    for (final line in lines) {
      byProvider.putIfAbsent(line.providerId, () => []).add(line);
    }

    return [
      for (final entry in byProvider.entries)
        SplitProviderOrderPlan(
          providerId: entry.key,
          lines: entry.value.map(_lineToOrderItem).toList(),
          fulfillmentMode: entry.key == systemProviderId
              ? FulfillmentMode.courier
              : FulfillmentMode.pickup,
          isAggregated: false,
          orderPriceEgp: entry.value.fold<double>(0, (s, l) => s + l.lineTotal),
          deliveryFeeEgp: 0,
          providerName: entry.value.first.providerName,
        ),
    ];
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
