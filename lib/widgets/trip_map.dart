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
    this.label,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final bool selected;

  /// Shown as a small number badge on the pin - the stop's position in an
  /// itinerary's visiting order. Null for markers with no assigned order
  /// (browsing mode, or the "my location" origin pin).
  final String? label;
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

/// Builds [LocationSettings] for a location request, tuned per platform -
/// shared by every place in the app that calls [Geolocator.getCurrentPosition]
/// or [Geolocator.getPositionStream].
///
/// On web specifically, this sets `maximumAge` so a recent-enough fix can be
/// served straight from the browser's own geolocation cache instead of
/// forcing a brand new lookup on every single call. Desktop browsers have no
/// GPS - position comes from a WiFi/IP-based lookup through the browser's
/// location service, which can take several seconds - and [WebSettings]'
/// own default `maximumAge` is [Duration.zero], meaning "never reuse a
/// cached fix," so without this override every tap of the locate button (or
/// every itinerary/direction request) pays that full lookup cost again even
/// seconds later. This can't fix the *accuracy* of that lookup - desktop
/// WiFi/IP geolocation is inherently coarser than a phone's GPS, and no
/// setting here changes that - but it does fix repeat calls being slow.
LocationSettings buildLocationSettings({
  LocationAccuracy accuracy = LocationAccuracy.high,
  int distanceFilter = 0,
  Duration? timeLimit,
}) {
  if (kIsWeb) {
    return WebSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
      maximumAge: const Duration(seconds: 60),
    );
  }
  return LocationSettings(
    accuracy: accuracy,
    distanceFilter: distanceFilter,
    timeLimit: timeLimit,
  );
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
    this.alwaysShowMyLocation = false,
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

  /// Shows the heading-aware "my location" puck from the start instead of
  /// waiting for the user to tap the locate button - used while following
  /// an itinerary, where knowing which way the user is facing matters right
  /// away rather than after an extra tap.
  final bool alwaysShowMyLocation;

  static bool get usesMapLibre =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  bool _showMyLocation = false;
  bool _locating = false;

  // Real GPS fixes are typically well under 50m of accuracy; anything past
  // this is almost certainly a WiFi/IP-based estimate instead.
  static const double _lowConfidenceAccuracyMeters = 1500;

  // MapLibre (Android/Web) renders the user-location puck itself, driven by
  // the native SDK's own GPS/compass; flutter_map (Windows) has no built-in
  // equivalent, so this also drives a plain marker manually there. Either
  // way it's kept here (rather than solely inside each platform view) so
  // this widget can also command an explicit camera recenter on every
  // locate-button tap - relying on the native "tracking mode" alone turned
  // out to not reliably repeat after the very first fix.
  Position? _myPosition;
  StreamSubscription<Position>? _positionSub;

  final GlobalKey<TripMapLibreViewState> _mapLibreKey = GlobalKey();
  final GlobalKey<TripMapFlutterMapViewState> _flutterMapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _showMyLocation = widget.alwaysShowMyLocation;
    if (widget.alwaysShowMyLocation) {
      unawaited(_startLocating());
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _onLocatePressed() async {
    if (_locating) return;
    await _startLocating();
  }

  void _flyTo(double lat, double lon) {
    if (TripMap.usesMapLibre) {
      unawaited(_mapLibreKey.currentState?.flyTo(lat, lon));
    } else {
      _flutterMapKey.currentState?.flyTo(lat, lon);
    }
  }

  Future<void> _startLocating() async {
    setState(() => _locating = true);
    final l10n = AppLocalizations.of(context)!;
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mapLocationServicesDisabled)));
      return;
    }
    final granted = await ensureLocationPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _locating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mapLocationPermissionDenied)));
      return;
    }
    setState(() => _showMyLocation = true);

    // Tracks whether the camera has already been moved for this request, so
    // it happens exactly once - either from the one-shot fix below, or (if
    // that fails/times out, e.g. a cold GPS) from the first update the live
    // stream delivers instead - never both, and never on every later tick.
    var flown = false;
    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: buildLocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 12),
        ),
      );
      if (mounted) {
        setState(() => _myPosition = current);
        _flyTo(current.latitude, current.longitude);
        flown = true;
        // A large accuracy radius (real GPS is usually well under 50m) is
        // the signature of a WiFi/IP-based fix rather than GPS - common on
        // desktop browsers, which have no GPS hardware to fall back on.
        // Surfacing that here explains an off-target pin instead of leaving
        // it looking like the app just got it wrong.
        if (current.accuracy > _lowConfidenceAccuracyMeters) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.mapLocationApproximate)));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.mapLocateFailed)));
      }
    }
    unawaited(_positionSub?.cancel());
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: buildLocationSettings(distanceFilter: 5),
        ).listen((position) {
          if (!mounted) return;
          setState(() => _myPosition = position);
          if (!flown) {
            flown = true;
            _flyTo(position.latitude, position.longitude);
          }
        });
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
    final myPosition = _myPosition;
    final myLocation = myPosition == null
        ? null
        : (
            lat: myPosition.latitude,
            lon: myPosition.longitude,
            // headingAccuracy is negative when the platform has no real
            // heading to give (e.g. stationary, or no compass hardware) -
            // only draw the arrow when it's genuine.
            heading: myPosition.headingAccuracy >= 0
                ? myPosition.heading
                : null,
          );
    final map = TripMap.usesMapLibre
        ? TripMapLibreView(
            key: _mapLibreKey,
            markers: widget.markers,
            routeGeometry: widget.routeGeometry,
            onMarkerTap: widget.onMarkerTap,
            onMapTapped: widget.onMapTapped,
            initialLat: widget.initialLat,
            initialLon: widget.initialLon,
            initialZoom: widget.initialZoom,
            myLocation: myLocation,
          )
        : TripMapFlutterMapView(
            key: _flutterMapKey,
            markers: widget.markers,
            routeGeometry: widget.routeGeometry,
            onMarkerTap: widget.onMarkerTap,
            onMapTapped: widget.onMapTapped,
            initialLat: widget.initialLat,
            initialLon: widget.initialLon,
            initialZoom: widget.initialZoom,
            myLocation: myLocation,
          );

    return Stack(
      children: [
        Positioned.fill(child: map),
        _locateButton(),
      ],
    );
  }
}
