import 'cart_line_for_split.dart';
import 'provider_delivery_config.dart';

class DeliveryFeeBreakdown {
  const DeliveryFeeBreakdown({
    required this.perProviderFees,
    required this.aggregatedFeeEgp,
    required this.totalDeliveryFeeEgp,
  });

  final Map<String, double> perProviderFees;
  final double aggregatedFeeEgp;
  final double totalDeliveryFeeEgp;
}

/// Calculates delivery fees per provider (not per item).
abstract final class DeliveryFeeCalculator {
  static double feeForProvider(ProviderDeliveryConfig config) {
    if (config.offersDelivery || config.freeDelivery) return 0;
    return config.deliveryFeeEgp;
  }

  /// [providerIds] participating in aggregated courier group.
  static DeliveryFeeBreakdown calculate({
    required List<CartLineForSplit> lines,
    required Map<String, ProviderDeliveryConfig> configs,
    required Set<String> storeDeliveryProviderIds,
    required Set<String> aggregatedCourierProviderIds,
    double platformFeeEgp = 0,
  }) {
    final perProvider = <String, double>{};
    var aggregated = 0.0;

    for (final pid in aggregatedCourierProviderIds) {
      final cfg = configs[pid] ?? ProviderDeliveryConfig(providerId: pid);
      final fee = feeForProvider(cfg);
      perProvider[pid] = fee;
      aggregated += fee;
    }

    for (final pid in storeDeliveryProviderIds) {
      perProvider[pid] = 0;
    }

    // Independent courier providers (case 3a) — each gets own fee
    final lineProviders = lines.map((l) => l.providerId).toSet();
    for (final pid in lineProviders) {
      if (storeDeliveryProviderIds.contains(pid)) continue;
      if (aggregatedCourierProviderIds.contains(pid)) continue;
      final cfg = configs[pid] ?? ProviderDeliveryConfig(providerId: pid);
      final fee = feeForProvider(cfg);
      perProvider[pid] = fee;
    }

    final independentFees = perProvider.entries
        .where((e) => !aggregatedCourierProviderIds.contains(e.key))
        .fold<double>(0, (sum, e) => sum + e.value);

    final total = independentFees + aggregated + platformFeeEgp;

    return DeliveryFeeBreakdown(
      perProviderFees: perProvider,
      aggregatedFeeEgp: aggregated + platformFeeEgp,
      totalDeliveryFeeEgp: total,
    );
  }
}
