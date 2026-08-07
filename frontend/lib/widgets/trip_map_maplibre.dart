import 'dart:async' show unawaited;
import 'dart:math' show Point;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/widgets/trip_map.dart' show TripMapMarker;

const Color _selectedMarkerColor = Color(0xFFF2A93B);
const Color _myLocationColorValue = Color(0xFF2ECC71);

/// MapLibre's CircleOptions takes color as a CSS-style hex string, not a
/// Flutter Color.
String _colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Renders a small filled-circle "number badge" bitmap for a numbered
/// itinerary stop, used as a MapLibre icon image instead of a text symbol.
///
/// Text symbols need glyphs served by the style's own font server (see
/// `SymbolOptions.fontNames`), but this plugin never actually wires that
/// property through to the native annotation manager on Android or Web -
/// any text symbol here silently renders with no visible glyph at all. A
/// bitmap sidesteps glyphs entirely: Flutter draws the digit itself with
/// its own bundled font, and the result is uploaded as a plain sprite
/// image, which MapLibre only ever needs to place - no font lookup at all.
Future<Uint8List> _renderNumberBadge(
  String label, {
  required Color color,
}) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
  const center = Offset(size / 2, size / 2);

  canvas.drawCircle(center, size / 2 - 4, Paint()..color = color);
  canvas.drawCircle(
    center,
    size / 2 - 4,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );

  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// Renders an upward-pointing arrowhead bitmap for the "my location" heading
/// indicator - same reasoning as [_renderNumberBadge]: a bitmap avoids the
/// same broken-glyph problem a Unicode arrow character would hit.
Future<Uint8List> _renderArrowIcon({required Color color}) async {
  const size = 80.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  final path = Path()
    ..moveTo(size / 2, 4)
    ..lineTo(size - 14, size - 16)
    ..lineTo(size / 2, size - 32)
    ..lineTo(14, size - 16)
    ..close();

  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(path, Paint()..color = color);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// MapLibre-backed map (Android/Web) - vector tiles from OpenFreeMap, a
/// free, no-signup, no-API-key tile host. Plain destination markers are
/// drawn as circle annotations (no image needed); numbered stops and the
/// "my location" arrow are drawn as bitmap icon images instead (see
/// [_renderNumberBadge]/[_renderArrowIcon]) since text symbols don't
/// reliably render on this plugin.
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
  /// Drawn as a custom green node (+ a heading arrow when available) rather
  /// than the platform SDK's native puck - the plugin doesn't expose a way
  /// to recolor that puck, and a plain blue dot wouldn't match the rest of
  /// this app's "you are here" styling on the other backend.
  final ({double lat, double lon, double? heading})? myLocation;

  @override
  State<TripMapLibreView> createState() => TripMapLibreViewState();
}

class TripMapLibreViewState extends State<TripMapLibreView> {
  MapLibreMapController? _controller;
  final Map<String, String> _circleIdToMarkerId = {};
  final Map<String, String> _symbolIdToMarkerId = {};

  // Sprite images only need registering once per name for the lifetime of
  // the controller - addImage calls after the first for the same name
  // would just be redundant Canvas work.
  final Set<String> _registeredImages = {};

  // The "you are here" node and its heading arrow, kept as separate
  // annotations from the destination markers above (updated via
  // updateCircle/updateSymbol on every position tick) so a GPS update
  // doesn't force a full clear-and-redraw of every destination pin too.
  Circle? _myLocationCircle;
  Symbol? _myLocationArrow;

  // Matches the flutter_map (Windows) backend's node color, so "this one is
  // you" looks the same regardless of which platform rendered the map.
  static const String _myLocationColor = '#2ECC71';
  static const String _myLocationArrowImage = 'my_location_arrow';

  // If flyTo is called before the map has finished initializing (a real
  // possibility - the locate button becomes tappable as soon as the page
  // is up, but the native map view can take a beat longer), the request
  // would otherwise just silently no-op since there's no controller yet to
  // send it to. Remembering it here and replaying it once the controller
  // shows up in _onMapCreated means a tap is never lost to that race.
  ({double lat, double lon, double zoom})? _pendingFlyTo;

  /// Recenters the map on [lat]/[lon] - called imperatively by TripMap's
  /// locate button each time it's pressed, rather than relying on
  /// `myLocationTrackingMode`'s passive camera-follow: that mode fights the
  /// user's own panning (it snaps straight back to the GPS position after
  /// every manual move, which reads as "broken" more than "helpful"), so
  /// this widget never enables it and drives all recentering itself instead.
  Future<void> flyTo(double lat, double lon, {double zoom = 17}) async {
    final controller = _controller;
    if (controller == null) {
      _pendingFlyTo = (lat: lat, lon: lon, zoom: zoom);
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lon), zoom),
    );
  }

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
    if (oldWidget.myLocation != widget.myLocation) {
      unawaited(_syncMyLocation());
    }
  }

  @override
  void dispose() {
    _controller?.onCircleTapped.remove(_handleCircleTapped);
    _controller?.onSymbolTapped.remove(_handleSymbolTapped);
    _controller?.onFeatureHover.remove(_handleFeatureHover);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onCircleTapped.add(_handleCircleTapped);
    controller.onSymbolTapped.add(_handleSymbolTapped);
    controller.onFeatureHover.add(_handleFeatureHover);
    final pending = _pendingFlyTo;
    if (pending != null) {
      _pendingFlyTo = null;
      unawaited(flyTo(pending.lat, pending.lon, zoom: pending.zoom));
    }
  }

  void _handleCircleTapped(Circle circle) {
    final markerId = _circleIdToMarkerId[circle.id];
    if (markerId != null) widget.onMarkerTap?.call(markerId);
  }

  void _handleSymbolTapped(Symbol symbol) {
    final markerId = _symbolIdToMarkerId[symbol.id];
    if (markerId != null) widget.onMarkerTap?.call(markerId);
  }

  void _handleFeatureHover(
    Point<double> point,
    LatLng coordinates,
    String id,
    Annotation? annotation,
    HoverEventType eventType,
  ) {
    final markerId = _circleIdToMarkerId[id] ?? _symbolIdToMarkerId[id];
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

  Future<void> _ensureImage(
    MapLibreMapController controller,
    String name,
    Future<Uint8List> Function() render,
  ) async {
    if (_registeredImages.contains(name)) return;
    final bytes = await render();
    await controller.addImage(name, bytes);
    _registeredImages.add(name);
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
    _symbolIdToMarkerId.clear();
    // clearCircles/clearSymbols above also wipes the "my location" node -
    // it's drawn with the same annotation types as the destination markers
    // below, just tracked separately. Drop these now-stale references so
    // _syncMyLocation recreates them fresh instead of trying to update
    // annotations that no longer exist on the map.
    _myLocationCircle = null;
    _myLocationArrow = null;

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

    // Built up here and sent via addCircles()/addSymbols() (one platform
    // channel call each) rather than calling addCircle()/addSymbol() once
    // per marker in a loop - the amenities layer alone can mean hundreds
    // of markers, and awaiting that many individual native round-trips
    // sequentially is exactly what made the map visibly freeze for a
    // couple of seconds every time the layer or a category got toggled.
    final circleOptions = <CircleOptions>[];
    final circleMarkerIds = <String>[];
    final symbolOptions = <SymbolOptions>[];
    final symbolMarkerIds = <String>[];

    for (final marker in widget.markers) {
      final label = marker.label;
      if (label != null) {
        // A numbered stop - drawn as a pre-rendered bitmap badge rather
        // than a circle + text symbol, since the text symbol never
        // actually rendered on this plugin (see _renderNumberBadge).
        final imageName = 'stop_$label';
        await _ensureImage(
          controller,
          imageName,
          () => _renderNumberBadge(label, color: _selectedMarkerColor),
        );
        symbolOptions.add(
          SymbolOptions(
            geometry: LatLng(marker.lat, marker.lon),
            iconImage: imageName,
            iconSize: 0.38,
          ),
        );
        symbolMarkerIds.add(marker.id);
      } else {
        circleOptions.add(
          CircleOptions(
            geometry: LatLng(marker.lat, marker.lon),
            circleRadius: marker.radius ?? (marker.selected ? 10 : 7),
            circleColor: marker.color != null
                ? _colorToHex(marker.color!)
                : (marker.selected ? '#F2A93B' : '#0A7E8C'),
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
        );
        circleMarkerIds.add(marker.id);
      }
    }

    if (circleOptions.isNotEmpty) {
      final circles = await controller.addCircles(circleOptions);
      for (var i = 0; i < circles.length; i++) {
        _circleIdToMarkerId[circles[i].id] = circleMarkerIds[i];
      }
    }
    if (symbolOptions.isNotEmpty) {
      final symbols = await controller.addSymbols(symbolOptions);
      for (var i = 0; i < symbols.length; i++) {
        _symbolIdToMarkerId[symbols[i].id] = symbolMarkerIds[i];
      }
    }

    await _syncMyLocation();
  }

  // Updates the "you are here" node in place rather than clearing/redrawing
  // it - only safe to call once the style has finished loading, same
  // constraint as _syncAnnotations.
  Future<void> _syncMyLocation() async {
    final controller = _controller;
    if (controller == null) return;
    final loc = widget.myLocation;

    if (loc == null) {
      final circle = _myLocationCircle;
      if (circle != null) {
        await controller.removeCircle(circle);
        _myLocationCircle = null;
      }
      final arrow = _myLocationArrow;
      if (arrow != null) {
        await controller.removeSymbol(arrow);
        _myLocationArrow = null;
      }
      return;
    }

    final target = LatLng(loc.lat, loc.lon);
    final circle = _myLocationCircle;
    if (circle == null) {
      _myLocationCircle = await controller.addCircle(
        CircleOptions(
          geometry: target,
          circleRadius: 9,
          circleColor: _myLocationColor,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );
    } else {
      await controller.updateCircle(circle, CircleOptions(geometry: target));
    }

    // headingAccuracy is negative when the platform has no real heading to
    // give (e.g. stationary, or no compass hardware) - only draw the arrow
    // when it's genuine, same rule the flutter_map backend follows.
    if (loc.heading != null) {
      await _ensureImage(
        controller,
        _myLocationArrowImage,
        () => _renderArrowIcon(color: _myLocationColorValue),
      );
      final arrow = _myLocationArrow;
      if (arrow == null) {
        _myLocationArrow = await controller.addSymbol(
          SymbolOptions(
            geometry: target,
            iconImage: _myLocationArrowImage,
            iconSize: 0.5,
            iconRotate: loc.heading,
          ),
        );
      } else {
        await controller.updateSymbol(
          arrow,
          SymbolOptions(geometry: target, iconRotate: loc.heading),
        );
      }
    } else if (_myLocationArrow != null) {
      await controller.removeSymbol(_myLocationArrow!);
      _myLocationArrow = null;
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
          onStyleLoadedCallback: () {
            unawaited(_syncAnnotations());
          },
          onMapClick: widget.onMapTapped == null
              ? null
              : (point, coordinates) => widget.onMapTapped!(
                  coordinates.latitude,
                  coordinates.longitude,
                ),
          compassEnabled: false,
          logoEnabled: false,
          // The native "my location" puck is deliberately left off - the
          // plugin doesn't expose a way to recolor it, so this app draws its
          // own green node/arrow instead (see _syncMyLocation), matching the
          // Windows backend's styling exactly rather than a default blue dot.
        ),
        _hoverLabel(),
      ],
    );
  }
}
