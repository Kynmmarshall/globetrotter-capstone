import 'dart:math' show Point;

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
    this.onMapTapped,
    required this.initialLat,
    required this.initialLon,
    required this.initialZoom,
    this.showMyLocation = false,
  });

  final List<TripMapMarker> markers;
  final List<RouteWaypoint>? routeGeometry;
  final void Function(String markerId)? onMarkerTap;
  final void Function(double lat, double lon)? onMapTapped;
  final double initialLat;
  final double initialLon;
  final double initialZoom;

  /// Shows the native blue dot + heading arrow at the device's GPS position,
  /// driven entirely by the platform SDK (Android sensors / browser
  /// Geolocation API) once location permission has been granted.
  final bool showMyLocation;

  @override
  State<TripMapLibreView> createState() => _TripMapLibreViewState();
}

class _TripMapLibreViewState extends State<TripMapLibreView> {
  MapLibreMapController? _controller;
  final Map<String, String> _circleIdToMarkerId = {};

  // Mouse-hover label - only ever populated on platforms that actually send
  // hover events (web has a real cursor; Android/iOS touch never fires
  // enter/move, so this simply stays null there).
  String? _hoveredLabel;
  Offset? _hoverPosition;

  @override
  void didUpdateWidget(covariant TripMapLibreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers ||
        oldWidget.routeGeometry != widget.routeGeometry) {
      _syncAnnotations();
    }
  }

  @override
  void dispose() {
    _controller?.onCircleTapped.remove(_handleCircleTapped);
    _controller?.onFeatureHover.remove(_handleFeatureHover);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onCircleTapped.add(_handleCircleTapped);
    controller.onFeatureHover.add(_handleFeatureHover);
  }

  void _handleCircleTapped(Circle circle) {
    final markerId = _circleIdToMarkerId[circle.id];
    if (markerId != null) widget.onMarkerTap?.call(markerId);
  }

  void _handleFeatureHover(
    Point<double> point,
    LatLng coordinates,
    String id,
    Annotation? annotation,
    HoverEventType eventType,
  ) {
    final markerId = _circleIdToMarkerId[id];
    if (markerId == null || eventType == HoverEventType.leave) {
      if (_hoveredLabel != null) setState(() => _hoveredLabel = null);
      return;
    }
    final marker = widget.markers.where((m) => m.id == markerId).firstOrNull;
    if (marker == null) return;
    setState(() {
      _hoveredLabel = marker.name;
      _hoverPosition = Offset(point.x, point.y);
    });
  }

  // Only safe to call once the style has actually finished loading -
  // adding annotations any earlier can silently no-op.
  Future<void> _syncAnnotations() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.clearCircles();
    await controller.clearLines();
    await controller.clearSymbols();
    _circleIdToMarkerId.clear();

    final route = widget.routeGeometry;
    if (route != null && route.isNotEmpty) {
      await controller.addLine(
        LineOptions(
          geometry: route.map((p) => LatLng(p.lat, p.lon)).toList(),
          lineColor: '#1E88E5',
          lineWidth: 4.0,
          lineOpacity: 0.9,
        ),
      );
    }

    for (final marker in widget.markers) {
      final circle = await controller.addCircle(
        CircleOptions(
          geometry: LatLng(marker.lat, marker.lon),
          circleRadius: marker.selected ? 10 : 7,
          circleColor: marker.selected ? '#F2A93B' : '#0A7E8C',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
      _circleIdToMarkerId[circle.id] = marker.id;

      if (marker.label != null) {
        // A text-only symbol layered on top of the circle - the visiting
        // order number. No icon image is registered/needed since this only
        // sets textField, not iconImage.
        await controller.addSymbol(
          SymbolOptions(
            geometry: LatLng(marker.lat, marker.lon),
            textField: marker.label,
            textSize: 11,
            textColor: '#FFFFFF',
            // Opaque, blurred halo - a soft fade behind the number rather
            // than a hard outline, so it stays readable over any tile color.
            textHaloColor: '#000000',
            textHaloWidth: 1.4,
            textHaloBlur: 0.6,
          ),
        );
      }
    }
  }

  Widget _hoverLabel() {
    final label = _hoveredLabel;
    final position = _hoverPosition;
    if (label == null || position == null) return const SizedBox.shrink();
    return Positioned(
      // Offset above-left of the cursor so the label doesn't sit under it.
      left: position.dx + 12,
      top: position.dy - 34,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A24).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          styleString: MapLibreStyles.openfreemapLiberty,
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.initialLat, widget.initialLon),
            zoom: widget.initialZoom,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _syncAnnotations,
          onMapClick: widget.onMapTapped == null
              ? null
              : (point, coordinates) => widget.onMapTapped!(
                  coordinates.latitude,
                  coordinates.longitude,
                ),
          compassEnabled: false,
          logoEnabled: false,
          myLocationEnabled: widget.showMyLocation,
          myLocationTrackingMode: widget.showMyLocation
              ? MyLocationTrackingMode.tracking
              : MyLocationTrackingMode.none,
          myLocationRenderMode: widget.showMyLocation
              ? MyLocationRenderMode.compass
              : MyLocationRenderMode.normal,
        ),
        _hoverLabel(),
      ],
    );
  }
}
