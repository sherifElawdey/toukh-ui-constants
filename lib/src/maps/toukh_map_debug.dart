import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Debug logging when a [GoogleMap] controller is created (QA / GCP verification).
void onToukhMapCreated(String screen, GoogleMapController controller) {
  if (!kDebugMode) return;
  debugPrint('════════ Google Map [$screen] controller ready ════════');
  debugPrint('Platform: $defaultTargetPlatform (web=$kIsWeb)');
  debugPrint(
    'If tiles stay gray, check docs/google-maps-setup.md '
    '(APIs enabled, billing, key restrictions for this app package/bundle).',
  );
  if (kIsWeb) {
    debugPrint(
      'Web: open DevTools → Console for gm_authFailure / RefererNotAllowedMapError.',
    );
  }
}

/// Wraps [onMapCreated] with debug logging.
void Function(GoogleMapController) toukhMapCreatedHandler(
  String screen,
  void Function(GoogleMapController controller) onReady,
) {
  return (controller) {
    onToukhMapCreated(screen, controller);
    onReady(controller);
  };
}
