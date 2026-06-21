import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_ui/src/maps/toukh_map_debug.dart';
import 'package:toukh_ui/src/maps/toukh_map_styles.dart';

/// [GoogleMap] with Toukh light/dark JSON styling applied from [Theme].
class ToukhGoogleMap extends StatefulWidget {
  const ToukhGoogleMap({
    super.key,
    this.debugScreenName,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.gestureRecognizers,
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
    this.cameraTargetBounds,
    this.mapType = MapType.normal,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomControlsEnabled = true,
    this.zoomGesturesEnabled = true,
    this.liteModeEnabled = false,
    this.tiltGesturesEnabled = true,
    this.fortyFiveDegreeImageryEnabled = false,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = true,
    this.layoutDirection,
    this.padding = EdgeInsets.zero,
    this.indoorViewEnabled = false,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.markers = const <Marker>{},
    this.polygons = const <Polygon>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.clusterManagers = const <ClusterManager>{},
    this.onCameraMove,
    this.onCameraMoveStarted,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
  });

  final String? debugScreenName;
  final CameraPosition initialCameraPosition;
  final MapCreatedCallback? onMapCreated;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final bool compassEnabled;
  final bool mapToolbarEnabled;
  final CameraTargetBounds? cameraTargetBounds;
  final MapType mapType;
  final MinMaxZoomPreference minMaxZoomPreference;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomControlsEnabled;
  final bool zoomGesturesEnabled;
  final bool liteModeEnabled;
  final bool tiltGesturesEnabled;
  final bool fortyFiveDegreeImageryEnabled;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final TextDirection? layoutDirection;
  final EdgeInsets padding;
  final bool indoorViewEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final Set<ClusterManager> clusterManagers;
  final VoidCallback? onCameraMoveStarted;
  final CameraPositionCallback? onCameraMove;
  final VoidCallback? onCameraIdle;
  final ArgumentCallback<LatLng>? onTap;
  final ArgumentCallback<LatLng>? onLongPress;

  @override
  State<ToukhGoogleMap> createState() => _ToukhGoogleMapState();
}

class _ToukhGoogleMapState extends State<ToukhGoogleMap> {
  GoogleMapController? _controller;
  Brightness? _lastBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyStyleIfNeeded();
  }

  void _applyStyleIfNeeded() {
    final brightness = Theme.of(context).brightness;
    if (_controller == null || _lastBrightness == brightness) return;
    _lastBrightness = brightness;
    final style = ToukhMapStyles.styleForBrightness(brightness);
    _controller!.setMapStyle(style);
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _lastBrightness = null;
    if (widget.debugScreenName != null) {
      onToukhMapCreated(widget.debugScreenName!, controller);
    }
    _applyStyleIfNeeded();
    widget.onMapCreated?.call(controller);
  }

  @override
  Widget build(BuildContext context) {
    final style = ToukhMapStyles.styleForBrightness(
      Theme.of(context).brightness,
    );

    return GoogleMap(
      initialCameraPosition: widget.initialCameraPosition,
      style: style,
      onMapCreated: _onMapCreated,
      gestureRecognizers: widget.gestureRecognizers ??
          const <Factory<OneSequenceGestureRecognizer>>{},
      compassEnabled: widget.compassEnabled,
      mapToolbarEnabled: widget.mapToolbarEnabled,
      cameraTargetBounds:
          widget.cameraTargetBounds ?? CameraTargetBounds.unbounded,
      mapType: widget.mapType,
      minMaxZoomPreference: widget.minMaxZoomPreference,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      liteModeEnabled: widget.liteModeEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      fortyFiveDegreeImageryEnabled: widget.fortyFiveDegreeImageryEnabled,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      layoutDirection: widget.layoutDirection,
      padding: widget.padding,
      indoorViewEnabled: widget.indoorViewEnabled,
      trafficEnabled: widget.trafficEnabled,
      buildingsEnabled: widget.buildingsEnabled,
      markers: widget.markers,
      polygons: widget.polygons,
      polylines: widget.polylines,
      circles: widget.circles,
      clusterManagers: widget.clusterManagers,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }
}
