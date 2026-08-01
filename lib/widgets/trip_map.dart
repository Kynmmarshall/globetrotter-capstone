import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/widgets/trip_map_flutter_map.dart';
import 'package:trip_io/widgets/trip_map_maplibre.dart';

/// A pin to render on the map - a destination, or the chosen origin/
/// destination for a route.
class TripMapMarker {
  const TripMapMarker({
    required this.id,
    required this.lat,
    required this.lon,
    this.selected = false,
  });

  final String id;
  final double lat;
  final double lon;
  final bool selected;
}

/// Yaoundé city-center default, used whenever there's nothing more specific
/// to center the map on.
const double yaoundeCenterLat = 3.8480;
const double yaoundeCenterLon = 11.5021;

/// Shows a map with destination pins and an optional route line - backed by
/// MapLibre on Android/Web (nicer vector-tile rendering, via the free
/// OpenFreeMap style) or flutter_map on Windows, since MapLibre has no
/// Windows implementation. Both render the exact same [markers] and
/// [routeGeometry]; callers don't need to know which backend is active.
class TripMap extends StatelessWidget {
  const TripMap({
    super.key,
    required this.markers,
    this.routeGeometry,
    this.onMarkerTap,
    this.initialLat = yaoundeCenterLat,
    this.initialLon = yaoundeCenterLon,
    this.initialZoom = 12.5,
  });

  final List<TripMapMarker> markers;
  final List<RouteWaypoint>? routeGeometry;
  final void Function(String markerId)? onMarkerTap;
  final double initialLat;
  final double initialLon;
  final double initialZoom;

  static bool get usesMapLibre => kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    if (usesMapLibre) {
      return TripMapLibreView(
        markers: markers,
        routeGeometry: routeGeometry,
        onMarkerTap: onMarkerTap,
        initialLat: initialLat,
        initialLon: initialLon,
        initialZoom: initialZoom,
      );
    }
    return TripMapFlutterMapView(
      markers: markers,
      routeGeometry: routeGeometry,
      onMarkerTap: onMarkerTap,
      initialLat: initialLat,
      initialLon: initialLon,
      initialZoom: initialZoom,
    );
  }
}
