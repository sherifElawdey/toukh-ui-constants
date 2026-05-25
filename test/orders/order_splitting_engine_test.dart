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
          ),
        },
      );
      expect(plan.providerOrders.length, 1);
      expect(plan.providerOrders.first.fulfillmentMode, FulfillmentMode.store);
      expect(plan.aggregatedGroupId, isNull);
      expect(plan.subtotalEgp, 100);
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
