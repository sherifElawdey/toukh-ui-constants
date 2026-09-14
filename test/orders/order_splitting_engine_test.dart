import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_ui/toukh_ui.dart';

void main() {
  group('OrderSplittingEngine', () {
    test('single provider with store delivery', () {
      final plan = OrderSplittingEngine.plan(
        lines: const [
          CartLineForSplit(
            providerId: 'p1',
            itemId: 'i1',
            title: 'Burger',
            quantity: 2,
            unitPrice: 50,
          ),
        ],
        providerConfigs: {
          'p1': const ProviderDeliveryConfig(
            providerId: 'p1',
            offersDelivery: true,
            deliveryFeeEgp: 15,
            pricingMode: StoreDeliveryPricingMode.fixed,
          ),
        },
      );
      expect(plan.providerOrders.length, 1);
      expect(plan.providerOrders.first.fulfillmentMode, FulfillmentMode.store);
      expect(plan.aggregatedGroupId, isNull);
      expect(plan.subtotalEgp, 100);
      expect(plan.deliveryFeeEgp, 15);
      expect(plan.providerOrders.first.deliveryFeeEgp, 15);
    });

    test('store free delivery stays zero', () {
      final plan = OrderSplittingEngine.plan(
        lines: const [
          CartLineForSplit(
            providerId: 'p1',
            itemId: 'i1',
            title: 'Burger',
            quantity: 1,
            unitPrice: 40,
          ),
        ],
        providerConfigs: {
          'p1': const ProviderDeliveryConfig(
            providerId: 'p1',
            offersDelivery: true,
            freeDelivery: true,
            deliveryFeeEgp: 20,
          ),
        },
      );
      expect(plan.deliveryFeeEgp, 0);
    });

    test('store perKm uses haversine distance', () {
      final plan = OrderSplittingEngine.plan(
        lines: const [
          CartLineForSplit(
            providerId: 'p1',
            itemId: 'i1',
            title: 'Burger',
            quantity: 1,
            unitPrice: 40,
          ),
        ],
        providerConfigs: {
          'p1': const ProviderDeliveryConfig(
            providerId: 'p1',
            offersDelivery: true,
            deliveryFeeEgp: 10,
            pricingMode: StoreDeliveryPricingMode.perKm,
            storeLat: 30.0,
            storeLng: 31.0,
          ),
        },
        customerLat: 30.01,
        customerLng: 31.0,
      );
      expect(plan.deliveryFeeEgp, greaterThan(0));
      final expectedKm = DeliveryFeeCalculator.haversineKm(30.0, 31.0, 30.01, 31.0);
      expect(plan.deliveryFeeEgp, (expectedKm * 10).roundToDouble());
    });

    test('explore lines have no delivery fee', () {
      final plan = OrderSplittingEngine.plan(
        lines: const [
          CartLineForSplit(
            providerId: 'system',
            itemId: 'e1',
            title: 'Explore item',
            quantity: 2,
            unitPrice: 25,
            serviceType: 'explore',
          ),
        ],
        providerConfigs: const {},
      );
      expect(plan.deliveryFeeEgp, 0);
      expect(plan.providerOrders.single.fulfillmentMode, FulfillmentMode.courier);
      expect(plan.subtotalEgp, 50);
    });

    test('multi provider all courier aggregates', () {
      final plan = OrderSplittingEngine.plan(
        lines: const [
          CartLineForSplit(
            providerId: 'p1',
            itemId: 'a',
            title: 'A',
            quantity: 1,
            unitPrice: 10,
          ),
          CartLineForSplit(
            providerId: 'p2',
            itemId: 'b',
            title: 'B',
            quantity: 1,
            unitPrice: 20,
          ),
        ],
        providerConfigs: {
          'p1': const ProviderDeliveryConfig(providerId: 'p1', deliveryFeeEgp: 7),
          'p2': const ProviderDeliveryConfig(providerId: 'p2', deliveryFeeEgp: 5),
        },
      );
      expect(plan.aggregatedGroupId, isNotNull);
      expect(plan.providerOrders.every((p) => p.isAggregated), isTrue);
      expect(plan.deliveryFeeEgp, 12);
    });
  });

  group('AggregatedOrderStateMachine', () {
    test('all responded when accepted or rejected', () {
      expect(
        AggregatedOrderStateMachine.allProvidersResponded({
          'p1': ProviderSubState.accepted,
          'p2': ProviderSubState.rejected,
        }),
        isTrue,
      );
    });
  });
}
