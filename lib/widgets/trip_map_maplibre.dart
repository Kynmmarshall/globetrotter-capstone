import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/widgets/trip_map.dart' show TripMapMarker;

/// MapLibre-backed map (Android/Web) - vector tiles from OpenFreeMap, a
/// free, no-signup, no-API-key tile host. Markers and the route line are
/// drawn as circle/line annotations rather than custom icon assets, which
/// keeps this working without shipping/registering marker images.
class TripMapLibreView extends StatefulWidget {
  const TripMapLibreView({
    super.key,
    required this.markers,
    this.routeGeometry,
    this.onMarkerTap,
    required this.initialLat,
    required this.initialLon,
    required this.initialZoom,
  });

  final List<TripMapMarker> markers;
  final List<RouteWaypoint>? routeGeometry;
  final void Function(String markerId)? onMarkerTap;
  final double initialLat;
  final double initialLon;
  final double initialZoom;

  @override
  State<TripMapLibreView> createState() => _TripMapLibreViewState();
}

class _TripMapLibreViewState extends State<TripMapLibreView> {
  MapLibreMapController? _controller;
  final Map<String, String> _circleIdToMarkerId = {};

  @override
  void didUpdateWidget(covariant TripMapLibreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers || oldWidget.routeGeometry != widget.routeGeometry) {
      _syncAnnotations();
    }
  }

  @override
  void dispose() {
    _controller?.onCircleTapped.remove(_handleCircleTapped);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onCircleTapped.add(_handleCircleTapped);
  }

  void _handleCircleTapped(Circle circle) {
    final markerId = _circleIdToMarkerId[circle.id];
    if (markerId != null) widget.onMarkerTap?.call(markerId);
  }

  // Only safe to call once the style has actually finished loading -
  // adding annotations any earlier can silently no-op.
  Future<void> _syncAnnotations() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.clearCircles();
    await controller.clearLines();
    _circleIdToMarkerId.clear();

    final route = widget.routeGeometry;
    if (route != null && route.isNotEmpty) {
      await controller.addLine(LineOptions(
        geometry: route.map((p) => LatLng(p.lat, p.lon)).toList(),
        lineColor: '#1E88E5',
        lineWidth: 4.0,
        lineOpacity: 0.9,
      ));
    }

    for (final marker in widget.markers) {
      final circle = await controller.addCircle(CircleOptions(
        geometry: LatLng(marker.lat, marker.lon),
        circleRadius: marker.selected ? 10 : 7,
        circleColor: marker.selected ? '#F2A93B' : '#0A7E8C',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ));
      _circleIdToMarkerId[circle.id] = marker.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: MapLibreStyles.openfreemapLiberty,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initialLat, widget.initialLon),
        zoom: widget.initialZoom,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _syncAnnotations,
      compassEnabled: false,
      logoEnabled: false,
    );
  }
}
