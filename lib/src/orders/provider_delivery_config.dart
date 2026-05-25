import 'package:equatable/equatable.dart';

/// Provider delivery pricing used by [DeliveryFeeCalculator].
class ProviderDeliveryConfig extends Equatable {
  const ProviderDeliveryConfig({
    required this.providerId,
    this.offersDelivery = false,
    this.deliveryFeeEgp = 0,
    this.freeDelivery = false,
  });

  final String providerId;
  final bool offersDelivery;
  final double deliveryFeeEgp;
  final bool freeDelivery;

  factory ProviderDeliveryConfig.fromMap(String providerId, Map<String, dynamic>? map) {
    if (map == null) {
      return ProviderDeliveryConfig(providerId: providerId);
    }
    final delivery = map['deliveryConfig'];
    final cfg = delivery is Map ? Map<String, dynamic>.from(delivery) : map;
    return ProviderDeliveryConfig(
      providerId: providerId,
      offersDelivery: cfg['offersDelivery'] as bool? ?? false,
      deliveryFeeEgp: (cfg['deliveryFeeEgp'] as num?)?.toDouble() ??
          (cfg['fixedDeliveryFee'] as num?)?.toDouble() ??
          0,
      freeDelivery: cfg['freeDelivery'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [providerId, offersDelivery, deliveryFeeEgp, freeDelivery];
}
