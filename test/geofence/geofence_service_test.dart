import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_ui/src/geofence/geofence_service.dart';
import 'package:toukh_ui/src/geofence/lat_lng_point.dart';

void main() {
  group('GeofenceService.containsLatLng', () {
    // Rough square around downtown Cairo.
    const square = [
      LatLngPoint(lat: 30.03, lng: 31.20),
      LatLngPoint(lat: 30.03, lng: 31.27),
      LatLngPoint(lat: 30.07, lng: 31.27),
      LatLngPoint(lat: 30.07, lng: 31.20),
    ];

    test('returns true for a point inside the polygon', () {
      expect(
        GeofenceService.containsLatLng(
          lat: 30.05,
          lng: 31.235,
          polygon: square,
        ),
        isTrue,
      );
    });

    test('returns false for a point outside the polygon', () {
      expect(
        GeofenceService.containsLatLng(
          lat: 30.10,
          lng: 31.235,
          polygon: square,
        ),
        isFalse,
      );
    });

    test('returns false when polygon has fewer than 3 points', () {
      expect(
        GeofenceService.containsLatLng(
          lat: 30.05,
          lng: 31.235,
          polygon: const [
            LatLngPoint(lat: 30.03, lng: 31.20),
            LatLngPoint(lat: 30.07, lng: 31.27),
          ],
        ),
        isFalse,
      );
    });
  });
}
