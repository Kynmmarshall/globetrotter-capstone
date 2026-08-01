import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/destination_detail_page.dart';
import 'package:trip_io/screens/itineraries_page.dart' show formatDuration;
import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/session_expired_card.dart';
import 'package:trip_io/widgets/trip_map.dart';

/// Sentinel [Destination.id] marking the synthetic "my current location"
/// entry a user can pick as a route start point - never a real destination.
const String _myLocationDestinationId = '__my_location__';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.session,
    this.focusDestination,
    this.showAppBar = false,
    this.itineraryDestinationIds,
    this.itineraryTitle,
  });

  final SessionController session;

  /// When set (e.g. opened via a destination's "View on map" button), the
  /// map centers on this destination and highlights it as the "to" point
  /// instead of the generic Yaoundé city-center default.
  final Destination? focusDestination;

  /// True when this page is pushed as its own standalone route rather than
  /// embedded as a dashboard tab - it then needs its own back button, since
  /// there's no dashboard AppBar/Scaffold around it to provide one.
  final bool showAppBar;

  /// When set (opened via an itinerary's "Start itinerary" button), the page
  /// switches into turn-by-turn mode: it resolves the device's current
  /// location as the route's start point and routes through these
  /// destination IDs, in order, as checkpoints - the usual From/To pickers
  /// are replaced with a read-only summary of the stops.
  final List<String>? itineraryDestinationIds;

  /// Shown in the AppBar title instead of the generic "Map" label when
  /// [itineraryDestinationIds] is set.
  final String? itineraryTitle;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<List<Destination>> _future;
  final TextEditingController _searchController = TextEditingController();

  Destination? _origin;
  Destination? _destination;
  String _profile = 'driving-car';
  RouteResult? _route;
  bool _routeLoading = false;
  String? _routeError;

  List<Destination> _allDestinations = [];
  bool _resolvingMyLocation = false;
  String? _myLocationError;

  bool get _isItineraryMode => widget.itineraryDestinationIds != null;

  List<Destination> get _itineraryCheckpoints {
    final ids = widget.itineraryDestinationIds;
    if (ids == null) return const [];
    final byId = {for (final d in _allDestinations) d.id: d};
    return ids
        .map((id) => byId[id])
        .whereType<Destination>()
        .where((d) => d.hasCoordinates)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _future = widget.session.destinations();
    unawaited(
      _future.then((list) {
        if (mounted) setState(() => _allDestinations = list);
      }),
    );
    _destination = widget.focusDestination;
    if (_isItineraryMode) {
      unawaited(_resolveMyLocationForItinerary());
    }
  }

  Future<void> _resolveMyLocationForItinerary() async {
    setState(() {
      _resolvingMyLocation = true;
      _myLocationError = null;
    });
    final granted = await ensureLocationPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _resolvingMyLocation = false;
        _myLocationError = AppLocalizations.of(
          context,
        )!.mapLocationPermissionDenied;
      });
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _origin = Destination(
          id: _myLocationDestinationId,
          name: AppLocalizations.of(context)!.mapMyLocationLabel,
          country: '',
          tags: const [],
          lat: position.latitude,
          lon: position.longitude,
        );
        _resolvingMyLocation = false;
      });
      unawaited(_computeRoute());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvingMyLocation = false;
        _myLocationError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<Destination?> _pickDestination(
    List<Destination> options,
    String title, {
    bool allowMyLocation = false,
  }) async {
    _searchController.clear();
    return showModalBottomSheet<Destination>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            // Lives here, one level above StatefulBuilder, so it survives
            // the setSheetState calls below instead of resetting each time.
            var locatingMe = false;
            String? locateError;
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1A24).withValues(alpha: 0.96),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setSheetState) {
                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = query.isEmpty
                          ? options
                          : options
                                .where(
                                  (d) => d.name.toLowerCase().contains(query),
                                )
                                .toList();
                      return Column(
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 6),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                hintText: AppLocalizations.of(
                                  context,
                                )!.mapSearchHint,
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          if (allowMyLocation) ...[
                            const SizedBox(height: 4),
                            ListTile(
                              leading: locatingMe
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                    ),
                              title: Text(
                                AppLocalizations.of(context)!.mapUseMyLocation,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: locateError != null
                                  ? Text(
                                      locateError!,
                                      style: TextStyle(
                                        color: Colors.red.shade100,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              onTap: locatingMe
                                  ? null
                                  : () async {
                                      setSheetState(() {
                                        locatingMe = true;
                                        locateError = null;
                                      });
                                      final granted =
                                          await ensureLocationPermission();
                                      if (!context.mounted) return;
                                      if (!granted) {
                                        setSheetState(() {
                                          locatingMe = false;
                                          locateError = AppLocalizations.of(
                                            context,
                                          )!.mapLocationPermissionDenied;
                                        });
                                        return;
                                      }
                                      try {
                                        final position =
                                            await Geolocator.getCurrentPosition();
                                        if (!context.mounted) return;
                                        Navigator.of(context).pop(
                                          Destination(
                                            id: _myLocationDestinationId,
                                            name: AppLocalizations.of(
                                              context,
                                            )!.mapMyLocationLabel,
                                            country: '',
                                            tags: const [],
                                            lat: position.latitude,
                                            lon: position.longitude,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        setSheetState(() {
                                          locatingMe = false;
                                          locateError = e.toString();
                                        });
                                      }
                                    },
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.12),
                              height: 1,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final d = filtered[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.place,
                                    color: Colors.white70,
                                  ),
                                  title: Text(
                                    d.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: (d.location ?? '').isNotEmpty
                                      ? Text(
                                          d.location!,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  onTap: () => Navigator.of(context).pop(d),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pointField({
    required IconData icon,
    required String label,
    required Destination? value,
    required List<Destination> options,
    required void Function(Destination) onPicked,
    bool allowMyLocation = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await _pickDestination(
          options,
          label,
          allowMyLocation: allowMyLocation,
        );
        if (picked != null) {
          onPicked(picked);
          _computeRoute();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value?.name ?? label,
                style: TextStyle(
                  color: value == null ? Colors.white60 : Colors.white,
                  fontSize: 13.5,
                  fontWeight: value == null ? FontWeight.w500 : FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null && !value.hasCoordinates)
              Tooltip(
                message: l10n.mapNoCoordinates,
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _itineraryStopChip(String label, {IconData icon = Icons.place}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItinerarySummary(
    AppLocalizations l10n,
    List<Destination> checkpoints,
  ) {
    if (_resolvingMyLocation) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.mapResolvingLocation,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      );
    }
    if (_myLocationError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _myLocationError!,
              style: TextStyle(color: Colors.red.shade100, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _resolveMyLocationForItinerary,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text(
              l10n.mapUseMyLocation,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _itineraryStopChip(l10n.mapMyLocationLabel, icon: Icons.my_location),
        for (final stop in checkpoints) ...[
          const Icon(Icons.arrow_forward, size: 13, color: Colors.white54),
          _itineraryStopChip(stop.name),
        ],
      ],
    );
  }

  void _swapPoints() {
    setState(() {
      final tmp = _origin;
      _origin = _destination;
      _destination = tmp;
    });
    _computeRoute();
  }

  /// The ordered stops the route should run through - origin plus either
  /// the itinerary's checkpoints (in itinerary mode) or the single manually
  /// picked destination. Null when there isn't enough to route yet.
  List<Destination>? get _routeStops {
    final origin = _origin;
    if (origin == null || !origin.hasCoordinates) return null;
    if (_isItineraryMode) {
      final checkpoints = _itineraryCheckpoints;
      if (checkpoints.isEmpty) return null;
      return [origin, ...checkpoints];
    }
    final destination = _destination;
    if (destination == null || !destination.hasCoordinates) return null;
    return [origin, destination];
  }

  Future<void> _computeRoute() async {
    final stops = _routeStops;
    if (stops == null) {
      setState(() {
        _route = null;
        _routeError = null;
      });
      return;
    }
    setState(() {
      _routeLoading = true;
      _routeError = null;
    });
    try {
      final waypoints = [
        for (final stop in stops) RouteWaypoint(lat: stop.lat!, lon: stop.lon!),
      ];
      final result = await widget.session.getRoute(
        waypoints,
        profile: _profile,
      );
      if (!mounted) return;
      setState(() => _route = result);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _routeError = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  void _clearRoute() {
    setState(() {
      _origin = null;
      _destination = null;
      _route = null;
      _routeError = null;
    });
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  Widget _profileChip(String value, IconData icon, String label) {
    final selected = _profile == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: selected ? Colors.white : Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _profile = value);
        _computeRoute();
      },
      // Material 3's default surface-tint/elevation washes a plain
      // backgroundColor/selectedColor out to near-white against this app's
      // light-brightness ColorScheme - `color` fully overrides that
      // resolution instead of layering on top of it.
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.85);
        }
        return const Color(0xFF13303B);
      }),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      showCheckmark: false,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      pressElevation: 0,
    );
  }

  void _onMarkerTap(String markerId, List<Destination> destinations) {
    final destination = destinations.where((d) => d.id == markerId).firstOrNull;
    if (destination == null) return;
    Analytics.instance.trackEvent('destination', 'view', name: destination.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DestinationDetailPage(
          destination: destination,
          heroTag: 'destination-${destination.id}',
          session: widget.session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scaffold = _buildScaffold(context, l10n);
    if (!widget.showAppBar) {
      // Embedded as a dashboard tab - the dashboard's own Stack already
      // paints the photo background behind this page's Scaffold.
      return scaffold;
    }
    // Pushed as its own standalone route (e.g. "View on map") - there's no
    // dashboard Stack behind it here, so without this the glass panels'
    // translucent white would sit on the default white Material background,
    // making their white text unreadable.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactBackground = constraints.maxWidth < 700;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              isCompactBackground
                  ? 'assets/backgrounds/mobile.png'
                  : 'assets/backgrounds/pc.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
              ),
            ),
            scaffold,
          ],
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.itineraryTitle ?? l10n.navMap),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: FutureBuilder<List<Destination>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (isAuthError(snapshot.error!)) {
              return SessionExpiredCard(session: widget.session);
            }
            return ErrorStateCard(
              message: l10n.destinationsLoadError(snapshot.error.toString()),
            );
          }
          final all = snapshot.data ?? <Destination>[];
          final withCoords = all.where((d) => d.hasCoordinates).toList();
          final checkpoints = _itineraryCheckpoints;
          final markers = _isItineraryMode
              ? [
                  if (_origin != null)
                    TripMapMarker(
                      id: _origin!.id,
                      name: _origin!.name,
                      lat: _origin!.lat!,
                      lon: _origin!.lon!,
                    ),
                  for (final stop in checkpoints)
                    TripMapMarker(
                      id: stop.id,
                      name: stop.name,
                      lat: stop.lat!,
                      lon: stop.lon!,
                      selected: true,
                    ),
                ]
              : [
                  for (final d in withCoords)
                    TripMapMarker(
                      id: d.id,
                      name: d.name,
                      lat: d.lat!,
                      lon: d.lon!,
                      selected: d.id == _origin?.id || d.id == _destination?.id,
                    ),
                ];
          final focus = widget.focusDestination;
          final firstCheckpoint = checkpoints.isNotEmpty
              ? checkpoints.first
              : null;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: _glassPanel(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alt_route, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isItineraryMode
                                  ? (widget.itineraryTitle ?? l10n.navMap)
                                  : l10n.mapTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!_isItineraryMode &&
                              (_origin != null || _destination != null))
                            TextButton(
                              onPressed: _clearRoute,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.mapClearRoute,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_isItineraryMode)
                        _buildItinerarySummary(l10n, checkpoints)
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _pointField(
                                    icon: Icons.trip_origin,
                                    label: l10n.mapFromLabel,
                                    value: _origin,
                                    options: withCoords,
                                    onPicked: (d) =>
                                        setState(() => _origin = d),
                                    allowMyLocation: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _pointField(
                                    icon: Icons.flag,
                                    label: l10n.mapToLabel,
                                    value: _destination,
                                    options: withCoords,
                                    onPicked: (d) =>
                                        setState(() => _destination = d),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed:
                                  (_origin == null && _destination == null)
                                  ? null
                                  : _swapPoints,
                              icon: const Icon(
                                Icons.swap_vert,
                                color: Colors.white70,
                              ),
                              tooltip: l10n.mapSwapButton,
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _profileChip(
                            'driving-car',
                            Icons.directions_car,
                            l10n.mapProfileDriving,
                          ),
                          _profileChip(
                            'foot-walking',
                            Icons.directions_walk,
                            l10n.mapProfileWalking,
                          ),
                          _profileChip(
                            'cycling-regular',
                            Icons.directions_bike,
                            l10n.mapProfileCycling,
                          ),
                        ],
                      ),
                      if (_routeLoading) ...[
                        const SizedBox(height: 10),
                        const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                      if (_routeError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _routeError!.contains('not configured')
                              ? l10n.mapRoutingNotConfigured
                              : l10n.mapRouteError(_routeError!),
                          style: TextStyle(
                            color: Colors.red.shade100,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (_route != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDistance(_route!.distanceMeters),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.schedule,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDuration(
                                Duration(
                                  seconds: _route!.durationSeconds.round(),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: TripMap(
                      markers: markers,
                      routeGeometry: _route?.geometry,
                      onMarkerTap: (id) => _onMarkerTap(id, withCoords),
                      initialLat:
                          firstCheckpoint?.lat ??
                          focus?.lat ??
                          yaoundeCenterLat,
                      initialLon:
                          firstCheckpoint?.lon ??
                          focus?.lon ??
                          yaoundeCenterLon,
                      initialZoom: (firstCheckpoint != null || focus != null)
                          ? 14
                          : 12.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
