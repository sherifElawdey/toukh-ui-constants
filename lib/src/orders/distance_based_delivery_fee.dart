import 'package:toukh_ui/src/orders/delivery_fee_calculator.dart';
import 'package:toukh_ui/src/settings/delivery_fee_settings.dart';

/// Result of [calculateDistanceBasedDeliveryFee] (mirrors CF fee calculator).
class DistanceBasedDeliveryFeeResult {
  const DistanceBasedDeliveryFeeResult({
    required this.deliveryFee,
    required this.billableDistanceMeters,
    required this.billableDistanceKm,
    required this.pricePerKm,
    required this.appliedMultiplier,
    required this.freeByThreshold,
  });

  final double deliveryFee;
  final double billableDistanceMeters;
  final double billableDistanceKm;
  final double pricePerKm;
  final double appliedMultiplier;
  final bool freeByThreshold;
}

double _round2(double v) => (v * 100).round() / 100;

double _applyDistanceRounding(double meters, DeliveryDistanceRounding policy) {
  final m = meters.isFinite && meters > 0 ? meters : 0.0;
  switch (policy) {
    case DeliveryDistanceRounding.ceil100m:
      return (m / 100).ceil() * 100.0;
    case DeliveryDistanceRounding.roundKm:
      return (m / 1000).round() * 1000.0;
    case DeliveryDistanceRounding.none:
      return m;
  }
}

bool _isNightHour(int hour, int start, int end) {
  if (start == end) return false;
  if (start < end) return hour >= start && hour < end;
  return hour >= start || hour < end;
}

/// Distance-based courier fee using admin [DeliveryFeeSettings] (haversine).
///
/// Mirrors `toukh/functions/orders/deliveryFeeCalculator.js`
/// `calculateDistanceBasedFee`.
DistanceBasedDeliveryFeeResult calculateDistanceBasedDeliveryFee({
  required DeliveryFeeSettings settings,
  required double distanceMeters,
  double subtotalEgp = 0,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final sub = subtotalEgp.isFinite && subtotalEgp > 0 ? subtotalEgp : 0.0;

  if (settings.freeDeliveryThreshold > 0 &&
      sub >= settings.freeDeliveryThreshold) {
    final rounded = _applyDistanceRounding(
      distanceMeters,
      settings.distanceRounding,
    );
    return DistanceBasedDeliveryFeeResult(
      deliveryFee: 0,
      billableDistanceMeters: rounded,
      billableDistanceKm: 0,
      pricePerKm: settings.pricePerKm,
      appliedMultiplier: 1,
      freeByThreshold: true,
    );
  }

  final billableMeters = _applyDistanceRounding(
    distanceMeters,
    settings.distanceRounding,
  );
  final billableKm = billableMeters / 1000;

  var multiplier = settings.surgeMultiplier;
  if (_isNightHour(
    clock.hour,
    settings.nightStartHour,
    settings.nightEndHour,
  )) {
    multiplier *= settings.nightMultiplier;
  }
  if (settings.rainActive) {
    multiplier *= settings.rainMultiplier;
  }

  var fee = billableKm * settings.pricePerKm * multiplier;
  fee = fee < settings.minimumDeliveryFee ? settings.minimumDeliveryFee : fee;
  fee = fee > settings.maximumDeliveryFee ? settings.maximumDeliveryFee : fee;
  fee = _round2(fee);

  return DistanceBasedDeliveryFeeResult(
    deliveryFee: fee,
    billableDistanceMeters: billableMeters,
    billableDistanceKm: _round2(billableKm * 1000) / 1000,
    pricePerKm: settings.pricePerKm,
    appliedMultiplier: _round2(multiplier * 1000) / 1000,
    freeByThreshold: false,
  );
}

/// Haversine meters between two lat/lng points.
double haversineMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) =>
    DeliveryFeeCalculator.haversineKm(lat1, lng1, lat2, lng2) * 1000;
