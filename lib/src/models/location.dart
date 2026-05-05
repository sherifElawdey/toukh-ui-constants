import 'package:equatable/equatable.dart';

/// Geographic point with optional human-readable label and formatted address.
///
/// Used by [OrderModel] for pickup and delivery points. Pure model — apps
/// map to/from Firestore (or any other backend) in their own data layers.
class Location extends Equatable {
  const Location({
    required this.lat,
    required this.lng,
    this.label,
    this.formattedAddress,
  });

  final double lat;
  final double lng;

  /// Short human-readable name (e.g. "Home", "Office"). Optional.
  final String? label;

  /// Long form address line for display (e.g. "15 Ramsis St, Garden City").
  final String? formattedAddress;

  Location copyWith({
    double? lat,
    double? lng,
    String? label,
    String? formattedAddress,
  }) {
    return Location(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
      formattedAddress: formattedAddress ?? this.formattedAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      if (label != null && label!.isNotEmpty) 'label': label,
      if (formattedAddress != null && formattedAddress!.isNotEmpty)
        'formattedAddress': formattedAddress,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      label: _string(map['label']),
      formattedAddress: _string(map['formattedAddress']),
    );
  }

  static String? _string(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  @override
  List<Object?> get props => [lat, lng, label, formattedAddress];
}
