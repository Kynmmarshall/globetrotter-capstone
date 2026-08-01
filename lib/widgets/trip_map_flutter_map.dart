import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:trip_io/models/models.dart';
import 'package:trip_io/widgets/trip_map.dart' show TripMapMarker;

/// flutter_map-backed map (Windows only - MapLibre has no Windows plugin
/// implementation). Pure-Dart raster tiles from OpenStreetMap, so it works
/// without any native platform bindings.
class TripMapFlutterMapView extends StatelessWidget {
  const TripMapFlutterMapView({
    super.key,
    required this.markers,
    this.routeGeometry,
    this.onMarkerTap,
    required this.initialLat,
    required this.initialLon,
    required this.initialZoom,
    this.myLocation,
  });

  final List<TripMapMarker> markers;
  final List<RouteWaypoint>? routeGeometry;
  final void Function(String markerId)? onMarkerTap;
  final double initialLat;
  final double initialLon;
  final double initialZoom;

  /// The device's current GPS position, if the user has granted permission -
  /// rendered as a plain dot. Unlike the MapLibre backend there's no native
  /// puck to lean on here, and Windows desktops have no compass hardware, so
  /// there's no heading arrow to draw.
  final ({double lat, double lon})? myLocation;

  Widget _pin({required bool selected}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFFF2A93B) : const Color(0xFF0A7E8C),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = routeGeometry ?? const [];

    return FlutterMap(
      options: MapOptions(
        initialCenter: ll.LatLng(initialLat, initialLon),
        initialZoom: initialZoom,
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
          markers: markers.map((marker) {
            final size = marker.selected ? 22.0 : 16.0;
            return Marker(
              point: ll.LatLng(marker.lat, marker.lon),
              width: size,
              height: size,
              // A generous hit area around the small pin so the tooltip and
              // tap target are actually easy to hit with a mouse.
              child: Tooltip(
                message: marker.name,
                child: GestureDetector(
                  onTap: onMarkerTap == null ? null : () => onMarkerTap!(marker.id),
                  child: _pin(selected: marker.selected),
                ),
              ),
            );
          }).toList(),
        ),
        if (myLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: ll.LatLng(myLocation!.lat, myLocation!.lon),
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E88E5),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
