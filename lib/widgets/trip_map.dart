import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/widgets/trip_map_flutter_map.dart';
import 'package:trip_io/widgets/trip_map_maplibre.dart';

/// A pin to render on the map - a destination, or the chosen origin/
/// destination for a route.
class TripMapMarker {
  const TripMapMarker({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.selected = false,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final bool selected;
}

/// Yaoundé city-center default, used whenever there's nothing more specific
/// to center the map on.
const double yaoundeCenterLat = 3.8480;
const double yaoundeCenterLon = 11.5021;

/// Requests location permission if needed and reports whether it's usable -
/// shared between this widget's own "locate me" button and the Map screen's
/// "use my current location as start point" option.
Future<bool> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) return false;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

/// Shows a map with destination pins and an optional route line - backed by
/// MapLibre on Android/Web (nicer vector-tile rendering, via the free
/// OpenFreeMap style) or flutter_map on Windows, since MapLibre has no
/// Windows implementation. Both render the exact same [markers] and
/// [routeGeometry]; callers don't need to know which backend is active.
class TripMap extends StatefulWidget {
  const TripMap({
    super.key,
    required this.markers,
    this.routeGeometry,
    this.onMarkerTap,
    this.onMapTapped,
    this.initialLat = yaoundeCenterLat,
    this.initialLon = yaoundeCenterLon,
    this.initialZoom = 12.5,
  });

  final List<TripMapMarker> markers;
  final List<RouteWaypoint>? routeGeometry;
  final void Function(String markerId)? onMarkerTap;

  /// Fires with the tapped coordinates whenever the map itself (not an
  /// existing marker) is tapped - used for "pick a location on the map"
  /// pickers rather than the usual browse/route views.
  final void Function(double lat, double lon)? onMapTapped;
  final double initialLat;
  final double initialLon;
  final double initialZoom;

  static bool get usesMapLibre =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  bool _showMyLocation = false;
  bool _locating = false;

  // MapLibre (Android/Web) renders the user-location puck itself, driven by
  // the native SDK's own GPS/compass - it only needs a "may I show it" flag.
  // flutter_map (Windows) has no built-in equivalent, so this drives a plain
  // marker manually; Windows desktops also have no compass hardware, so
  // there's no heading to show there, just a position dot.
  Position? _myPosition;
  StreamSubscription<Position>? _positionSub;

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _onLocatePressed() async {
    if (_locating) return;
    setState(() => _locating = true);
    final granted = await ensureLocationPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.mapLocationPermissionDenied,
          ),
        ),
      );
      return;
    }
    setState(() => _showMyLocation = true);
    if (!TripMap.usesMapLibre) {
      try {
        final current = await Geolocator.getCurrentPosition();
        if (mounted) setState(() => _myPosition = current);
      } catch (_) {
        // Fall through to the live stream below - a single fix can fail
        // (e.g. cold GPS) even though the stream still comes up fine.
      }
      unawaited(_positionSub?.cancel());
      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) {
            if (mounted) setState(() => _myPosition = position);
          });
    }
    if (mounted) setState(() => _locating = false);
  }

  Widget _locateButton() {
    return Positioned(
      // Left, not right - the dashboard's AI chat FAB sits fixed at the
      // bottom-right of every screen and would otherwise sit on top of this.
      left: 12,
      bottom: 12,
      child: Material(
        color: _showMyLocation
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF0B1A24),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _onLocatePressed,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = TripMap.usesMapLibre
        ? TripMapLibreView(
            markers: widget.markers,
            routeGeometry: widget.routeGeometry,
            onMarkerTap: widget.onMarkerTap,
            onMapTapped: widget.onMapTapped,
            initialLat: widget.initialLat,
            initialLon: widget.initialLon,
            initialZoom: widget.initialZoom,
            showMyLocation: _showMyLocation,
          )
        : TripMapFlutterMapView(
            markers: widget.markers,
            routeGeometry: widget.routeGeometry,
            onMarkerTap: widget.onMarkerTap,
            onMapTapped: widget.onMapTapped,
            initialLat: widget.initialLat,
            initialLon: widget.initialLon,
            initialZoom: widget.initialZoom,
            myLocation: _myPosition == null
                ? null
                : (
                    lat: _myPosition!.latitude,
                    lon: _myPosition!.longitude,
                    // headingAccuracy is negative when the platform has no
                    // real heading to give (e.g. stationary, or no compass
                    // hardware) - only draw the arrow when it's genuine.
                    heading: _myPosition!.headingAccuracy >= 0
                        ? _myPosition!.heading
                        : null,
                  ),
          );

    return Stack(
      children: [
        Positioned.fill(child: map),
        _locateButton(),
      ],
    );
  }
}
