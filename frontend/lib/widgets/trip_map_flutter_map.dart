import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:trip_io/models/models.dart';
import 'package:trip_io/widgets/trip_map.dart' show TripMapMarker;

/// flutter_map-backed map (Windows only - MapLibre has no Windows plugin
/// implementation). Pure-Dart raster tiles from OpenStreetMap, so it works
/// without any native platform bindings.
class TripMapFlutterMapView extends StatefulWidget {
  const TripMapFlutterMapView({
    super.key,
    required this.markers,
    this.routeGeometry,
    this.onMarkerTap,
    this.onMapTapped,
    required this.initialLat,
    required this.initialLon,
    required this.initialZoom,
    this.myLocation,
  });

  final List<TripMapMarker> markers;
  final List<RouteWaypoint>? routeGeometry;
  final void Function(String markerId)? onMarkerTap;
  final void Function(double lat, double lon)? onMapTapped;
  final double initialLat;
  final double initialLon;
  final double initialZoom;

  /// The device's current GPS position, if the user has granted permission.
  /// [myLocation.heading] is only non-null when the platform actually has a
  /// real heading to report (most Windows desktops have no compass hardware
  /// and won't) - the arrow is only drawn in that case.
  final ({double lat, double lon, double? heading})? myLocation;

  @override
  State<TripMapFlutterMapView> createState() => TripMapFlutterMapViewState();
}

class TripMapFlutterMapViewState extends State<TripMapFlutterMapView> {
  final MapController _mapController = MapController();

  /// Recenters the map on [lat]/[lon] - called imperatively by TripMap's
  /// locate button each time it's pressed, rather than being inferred from
  /// prop changes, so every tap reliably pans the camera even if the fresh
  /// position happens to be the same as (or very close to) the last one.
  void flyTo(double lat, double lon, {double zoom = 17}) {
    _mapController.move(ll.LatLng(lat, lon), zoom);
  }

  // A friendly, clearly-visible green rather than the usual map-app blue -
  // distinct from both the teal/orange destination pins and the blue route
  // line, so "this one is you" reads at a glance.
  static const Color _myLocationColor = Color(0xFF2ECC71);

  Widget _myLocationMarker({double? heading}) {
    final node = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _myLocationColor,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)],
      ),
    );
    if (heading == null) return Center(child: node);
    return Stack(
      alignment: Alignment.center,
      children: [
        // 0deg is due north, matching Icons.navigation's default up-pointing
        // orientation - rotating it by the heading (clockwise, in radians)
        // points it exactly where the device is facing.
        Transform.rotate(
          angle: heading * (math.pi / 180),
          child: const Icon(
            Icons.navigation,
            color: _myLocationColor,
            size: 34,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        node,
      ],
    );
  }

  Widget _pin({required bool selected, String? label, Color? color}) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? (selected ? const Color(0xFFF2A93B) : const Color(0xFF0A7E8C)),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: label == null
          ? null
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.routeGeometry ?? const [];
    final myLocation = widget.myLocation;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ll.LatLng(widget.initialLat, widget.initialLon),
        initialZoom: widget.initialZoom,
        onTap: widget.onMapTapped == null
            ? null
            : (_, point) =>
                  widget.onMapTapped!(point.latitude, point.longitude),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'trip_io',
        ),
        if (route.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.map((p) => ll.LatLng(p.lat, p.lon)).toList(),
                strokeWidth: 4,
                color: const Color(0xFF1E88E5),
              ),
            ],
          ),
        MarkerLayer(
          markers: widget.markers.map((marker) {
            final size = marker.radius != null
                ? marker.radius! * 2
                : (marker.label != null
                      ? 24.0
                      : (marker.selected ? 22.0 : 16.0));
            return Marker(
              point: ll.LatLng(marker.lat, marker.lon),
              width: size,
              height: size,
              // A generous hit area around the small pin so the tooltip and
              // tap target are actually easy to hit with a mouse.
              child: Tooltip(
                message: marker.name,
                child: GestureDetector(
                  onTap: widget.onMarkerTap == null
                      ? null
                      : () => widget.onMarkerTap!(marker.id),
                  child: _pin(
                    selected: marker.selected,
                    label: marker.label,
                    color: marker.color,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (myLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: ll.LatLng(myLocation.lat, myLocation.lon),
                width: myLocation.heading != null ? 34 : 22,
                height: myLocation.heading != null ? 34 : 22,
                child: _myLocationMarker(heading: myLocation.heading),
              ),
            ],
          ),
      ],
    );
  }
}
