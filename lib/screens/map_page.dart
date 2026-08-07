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
import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/widgets/amenities_legend.dart';
import 'package:trip_io/widgets/amenity_categories.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/order_destinations_sheet.dart';
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
    this.directionsFromMyLocation = false,
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

  /// When set together with [focusDestination] (opened via a "Directions"
  /// button rather than a plain "View on map" one), the page resolves the
  /// device's current location as the route's origin and computes the route
  /// to that destination right away, instead of leaving the From field for
  /// the user to fill in themselves.
  final bool directionsFromMyLocation;

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

  // Live-selected itinerary state - seeded from the constructor params but
  // reassignable from within this screen itself via "select itinerary", so
  // a user can browse into itinerary-following mode without having come
  // from the itinerary detail page's "Start itinerary" button.
  List<String>? _itineraryIds;
  String? _itineraryTitle;
  final Set<String> _visitedIds = {};
  StreamSubscription<Position>? _positionSub;

  // Keeps the "next stop"/"remaining" distance-and-time figures from going
  // stale as the user actually walks/drives, without re-requesting a route
  // on every single GPS tick (the position stream can fire every few
  // meters) - a real re-route only every so often, plus an immediate one
  // the moment a stop is reached (see _updateVisitedProgress), when the
  // remaining path actually changes shape.
  static const Duration _routeRefreshInterval = Duration(seconds: 45);
  Timer? _routeRefreshTimer;

  // Nearby-amenities layer (hospitals, pharmacies, fuel stations, hotels,
  // banks/ATMs, police) - opt-in and off by default, same "don't clutter
  // the map uninvited" philosophy as the options panel starting collapsed.
  List<MapAmenity> _amenities = [];
  bool _amenitiesEnabled = false;
  bool _amenitiesLegendExpanded = false;
  bool _amenitiesFetchedOnce = false;
  final Set<String> _enabledAmenityCategories = amenityCategories.toSet();
  ({double lat, double lon})? _lastAmenityFetchAnchor;

  // Half the backend's 1500m query radius - re-fetching only once the
  // anchor has moved this far keeps a slow walk/drive from re-querying
  // Overpass on every step while still keeping the layer relevant.
  static const double _amenityRefetchMinMoveMeters = 250;

  // The options panel starts collapsed so the map fills the whole screen -
  // "get directions"/"my location"/"select itinerary" live behind this
  // toggle instead of a permanently fixed panel.
  bool _panelExpanded = false;

  bool get _isItineraryMode => _itineraryIds != null;

  /// The checkpoints still ahead - everything in [_itineraryCheckpoints]
  /// not yet marked visited. This (not the full checkpoint list) is what
  /// actually gets routed through: re-routing through a stop already
  /// reached would both inflate the "remaining" distance/time and draw the
  /// line looping back to somewhere the user has already been.
  List<Destination> get _remainingCheckpoints => _itineraryCheckpoints
      .where((c) => !_visitedIds.contains(c.id))
      .toList();

  List<Destination> get _itineraryCheckpoints {
    final ids = _itineraryIds;
    if (ids == null) return const [];
    final byId = {for (final d in _allDestinations) d.id: d};
    return ids
        .map((id) => byId[id])
        .whereType<Destination>()
        .where((d) => d.hasCoordinates)
        .toList();
  }

  /// Where "nearby" means "nearby to" - reuses the exact same precedence
  /// already used to pick the map's initial camera position (see
  /// _buildScaffold's `firstCheckpoint?.lat ?? focus?.lat ?? ...`), rather
  /// than a separate "true visible map center" concept the map backends
  /// don't currently expose a way to track live anyway.
  ({double lat, double lon})? get _amenityAnchor {
    final checkpoint = _remainingCheckpoints.isNotEmpty
        ? _remainingCheckpoints.first
        : null;
    final focus = widget.focusDestination;
    final lat = checkpoint?.lat ?? focus?.lat ?? _destination?.lat ?? _origin?.lat;
    final lon = checkpoint?.lon ?? focus?.lon ?? _destination?.lon ?? _origin?.lon;
    if (lat == null || lon == null) return null;
    return (lat: lat, lon: lon);
  }

  /// Fetches amenities around [_amenityAnchor], throttled so a slow walk or
  /// a stream of GPS ticks doesn't hammer the backend - only re-fetches once
  /// the anchor has actually moved past [_amenityRefetchMinMoveMeters], or
  /// when [force] is set (the layer was just switched on, or the anchor
  /// changed in a way worth an immediate refresh rather than waiting).
  Future<void> _refreshAmenities({bool force = false}) async {
    if (!_amenitiesEnabled) return;
    final anchor = _amenityAnchor;
    if (anchor == null) return;
    final last = _lastAmenityFetchAnchor;
    if (!force &&
        last != null &&
        Geolocator.distanceBetween(last.lat, last.lon, anchor.lat, anchor.lon) <
            _amenityRefetchMinMoveMeters) {
      return;
    }
    _lastAmenityFetchAnchor = anchor;
    try {
      final result = await widget.session.amenities(
        lat: anchor.lat,
        lon: anchor.lon,
      );
      if (!mounted) return;
      setState(() {
        _amenities = result;
        _amenitiesFetchedOnce = true;
      });
    } catch (_) {
      // Best-effort overlay - a failed lookup just means no dots show up,
      // never an error state on top of the rest of the map.
      if (mounted) setState(() => _amenitiesFetchedOnce = true);
    }
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
    _itineraryIds = widget.itineraryDestinationIds;
    _itineraryTitle = widget.itineraryTitle;
    // Arriving with a specific destination or itinerary already in hand is a
    // deliberate "show me the route" intent - skip making the user tap the
    // toggle to see what they came here for. Plain browsing (the dashboard
    // tab, no params) starts collapsed so the map fills the screen.
    _panelExpanded = widget.focusDestination != null || _isItineraryMode;
    if (_isItineraryMode) {
      unawaited(_startItineraryTracking());
    } else if (widget.directionsFromMyLocation &&
        widget.focusDestination != null) {
      unawaited(_resolveMyLocationForDirections());
    } else {
      // Itinerary mode and the directions-button flow already ask (via
      // _startItineraryTracking / _resolveMyLocationForDirections) - for
      // every other way of opening this screen, ask up front too instead of
      // waiting for the user to discover the locate button and tap it.
      unawaited(ensureLocationPermission());
    }
  }

  /// One-shot version of [_startItineraryTracking]'s location resolution -
  /// used by the "Directions" button flow, which only needs a single origin
  /// fix to compute one route rather than a continuously updating position
  /// for progress-tracking along several stops.
  Future<void> _resolveMyLocationForDirections() async {
    final granted = await ensureLocationPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.mapLocationPermissionDenied,
          ),
        ),
      );
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: buildLocationSettings(
          timeLimit: const Duration(seconds: 12),
        ),
      );
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
      });
      unawaited(_computeRoute());
      unawaited(_refreshAmenities(force: true));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mapLocateFailed)),
      );
    }
  }

  Future<void> _startItineraryTracking() async {
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
      final position = await Geolocator.getCurrentPosition(
        locationSettings: buildLocationSettings(
          timeLimit: const Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      _applyPosition(position);
      setState(() => _resolvingMyLocation = false);
      unawaited(_computeRoute());
      unawaited(_refreshAmenities(force: true));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvingMyLocation = false;
        _myLocationError = e.toString();
      });
    }
    if (!mounted) return;
    // A continuous stream, not just the one-shot fix above - both to keep
    // the origin marker moving with the user and to detect when they get
    // close enough to a checkpoint to count it as visited.
    unawaited(_positionSub?.cancel());
    _positionSub = Geolocator.getPositionStream(
      locationSettings: buildLocationSettings(distanceFilter: 15),
    ).listen(_applyPosition);
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = Timer.periodic(
      _routeRefreshInterval,
      (_) => unawaited(_computeRoute()),
    );
  }

  void _applyPosition(Position position) {
    if (!mounted) return;
    late bool reachedNewStop;
    setState(() {
      _origin = Destination(
        id: _myLocationDestinationId,
        name: AppLocalizations.of(context)!.mapMyLocationLabel,
        country: '',
        tags: const [],
        lat: position.latitude,
        lon: position.longitude,
      );
      reachedNewStop = _updateVisitedProgress(position);
    });
    // Outside setState (not inside it) since this kicks off an async
    // request of its own - the remaining path just changed shape (one
    // fewer stop to route through), so the "next stop"/"remaining" figures
    // would otherwise sit stale until the next periodic refresh. The
    // amenity anchor is the next checkpoint's own fixed coordinates (see
    // _amenityAnchor), not the live position, so it only actually moves
    // when a stop is reached - no point re-checking on every GPS tick.
    if (reachedNewStop) {
      unawaited(_computeRoute());
      unawaited(_refreshAmenities(force: true));
    }
  }

  // A checkpoint counts as visited once the user has physically come within
  // this radius of it - close enough to be a deliberate stop rather than
  // just passing nearby on the way to somewhere else.
  static const double _visitRadiusMeters = 120;

  bool _updateVisitedProgress(Position position) {
    var reachedNewStop = false;
    for (final checkpoint in _itineraryCheckpoints) {
      if (_visitedIds.contains(checkpoint.id)) continue;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        checkpoint.lat!,
        checkpoint.lon!,
      );
      if (distance <= _visitRadiusMeters) {
        _visitedIds.add(checkpoint.id);
        reachedNewStop = true;
      }
    }
    return reachedNewStop;
  }

  Future<void> _selectItinerary() async {
    final l10n = AppLocalizations.of(context)!;
    List<Itinerary> itineraries;
    try {
      itineraries = await widget.session.itineraries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }
    if (!mounted) return;
    if (itineraries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mapNoItinerariesAvailable)));
      return;
    }

    final chosen = await showModalBottomSheet<Itinerary>(
      context: context,
      backgroundColor: const Color(0xFF13253A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.mapSelectItinerarySheetTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final itinerary in itineraries)
                      ListTile(
                        leading: const Icon(
                          Icons.map_outlined,
                          color: Colors.white70,
                        ),
                        title: Text(
                          itinerary.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${itinerary.destinations.length}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () => Navigator.of(context).pop(itinerary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    final ordered = await showOrderDestinationsSheet(
      context,
      destinationIds: chosen.destinations,
      destinationsById: {for (final d in _allDestinations) d.id: d},
    );
    if (ordered == null || !mounted) return;

    unawaited(_positionSub?.cancel());
    setState(() {
      _itineraryIds = ordered;
      _itineraryTitle = chosen.title;
      _visitedIds.clear();
      _origin = null;
      _route = null;
      _panelExpanded = false;
    });
    unawaited(_startItineraryTracking());
  }

  void _leaveItineraryMode() {
    unawaited(_positionSub?.cancel());
    _routeRefreshTimer?.cancel();
    setState(() {
      _itineraryIds = null;
      _itineraryTitle = null;
      _visitedIds.clear();
      _origin = null;
      _destination = null;
      _route = null;
      _routeError = null;
      // The checkpoint anchor is gone now - clear stale dots rather than
      // leaving them parked over wherever the itinerary last pointed.
      _amenities = [];
      _lastAmenityFetchAnchor = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    unawaited(_positionSub?.cancel());
    _routeRefreshTimer?.cancel();
    super.dispose();
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
                                            await Geolocator.getCurrentPosition(
                                              locationSettings:
                                                  buildLocationSettings(
                                                    timeLimit: const Duration(
                                                      seconds: 12,
                                                    ),
                                                  ),
                                            );
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
          unawaited(_refreshAmenities(force: true));
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
            onPressed: _startItineraryTracking,
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
      final checkpoints = _remainingCheckpoints;
      if (checkpoints.isEmpty) return null;
      return [origin, ...checkpoints];
    }
    final destination = _destination;
    if (destination == null || !destination.hasCoordinates) return null;
    return [origin, destination];
  }

  // Sentinel _routeError value (never something the server sends) marking
  // the GPS-plausibility check below having tripped, so the error display
  // can show a distinct, actionable message instead of a raw server string.
  static const String _locationTooFarError = '__location_too_far__';

  // A GPS fix this far from the destination(s) means the position is very
  // likely wrong (stale cache, WiFi/IP-based geolocation guessing the wrong
  // city or country, an emulator's default location, ...) rather than the
  // user actually having travelled there - worth catching before spending a
  // routing API call on two points that were never going to connect.
  static const double _implausibleDistanceMeters = 300000;

  Future<void> _computeRoute() async {
    final stops = _routeStops;
    if (stops == null) {
      setState(() {
        _route = null;
        _routeError = null;
      });
      return;
    }
    final origin = stops.first;
    if (origin.id == _myLocationDestinationId) {
      final nearest = stops.skip(1).first;
      final distance = Geolocator.distanceBetween(
        origin.lat!,
        origin.lon!,
        nearest.lat!,
        nearest.lon!,
      );
      if (distance > _implausibleDistanceMeters) {
        setState(() {
          _route = null;
          _routeError = _locationTooFarError;
        });
        return;
      }
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

  String _routeErrorMessage(AppLocalizations l10n) {
    final error = _routeError!;
    if (error == _locationTooFarError) return l10n.mapLocationTooFar;
    if (error.contains('not configured')) return l10n.mapRoutingNotConfigured;
    if (error.contains('No route could be found')) return l10n.mapNoRouteFound;
    return l10n.mapRouteError(error);
  }

  bool get _canRetryRoute {
    final error = _routeError;
    if (error == null) return false;
    // Not offered for "not configured" (a server-side setup problem) or
    // "no route found" (ORS's own final word on these exact points) -
    // retrying can't change either. The too-far case keeps its retry: by
    // the time it's tapped again, the live GPS stream may have delivered a
    // better fix than the one that tripped the check.
    return !error.contains('not configured') &&
        !error.contains('No route could be found');
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
    if (markerId.startsWith('amenity:')) {
      final amenity = _amenities
          .where((a) => 'amenity:${a.id}' == markerId)
          .firstOrNull;
      if (amenity != null) _showAmenitySheet(amenity);
      return;
    }
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

  // Amenities aren't curated Destinations (no detail page, no ratings) - a
  // lightweight sheet with the one action that actually matters ("get me
  // there") is what turns the layer from decorative into useful, per the
  // feature's own point: showing "locations they can access."
  void _showAmenitySheet(MapAmenity amenity) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF13253A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: amenityCategoryColor(amenity.category),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    amenityCategoryIcon(amenity.category),
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    amenityCategoryLabel(amenity.category, l10n),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                amenity.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    setState(() {
                      _destination = Destination(
                        id: 'osm:${amenity.id}',
                        name: amenity.name,
                        country: '',
                        tags: const [],
                        lat: amenity.lat,
                        lon: amenity.lon,
                      );
                    });
                    _computeRoute();
                  },
                  icon: const Icon(Icons.directions),
                  label: Text(l10n.mapAmenityDirectionsButton),
                ),
              ),
            ],
          ),
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
              decoration: BoxDecoration(color: context.tripColors.scrim),
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
              title: Text(_itineraryTitle ?? l10n.navMap),
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
          final visitedCount = checkpoints
              .where((c) => _visitedIds.contains(c.id))
              .length;
          final markers = _isItineraryMode
              ? [
                  // No pin for the origin here - the heading-aware "my
                  // location" puck (below, via alwaysShowMyLocation) shows
                  // the user's own position instead, so it isn't drawn twice.
                  for (var i = 0; i < checkpoints.length; i++)
                    TripMapMarker(
                      id: checkpoints[i].id,
                      name: checkpoints[i].name,
                      lat: checkpoints[i].lat!,
                      lon: checkpoints[i].lon!,
                      selected: true,
                      label: '${i + 1}',
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
          if (_amenitiesEnabled) {
            for (final a in _amenities.where(
              (a) => _enabledAmenityCategories.contains(a.category),
            )) {
              markers.add(
                TripMapMarker(
                  id: 'amenity:${a.id}',
                  name: a.name,
                  lat: a.lat,
                  lon: a.lon,
                  color: amenityCategoryColor(a.category),
                  radius: 5,
                ),
              );
            }
          }
          final focus = widget.focusDestination;
          final firstCheckpoint = checkpoints.isNotEmpty
              ? checkpoints.first
              : null;
          // Below the AppBar (if any) plus a little breathing room, so the
          // floating controls never sit under the status bar/notch even
          // though the map itself extends fully behind them.
          final topInset =
              (widget.showAppBar ? 0.0 : MediaQuery.of(context).padding.top) +
              12;

          return Stack(
            children: [
              Positioned.fill(
                child: TripMap(
                  markers: markers,
                  routeGeometry: _route?.geometry,
                  onMarkerTap: (id) => _onMarkerTap(id, withCoords),
                  initialLat:
                      firstCheckpoint?.lat ?? focus?.lat ?? yaoundeCenterLat,
                  initialLon:
                      firstCheckpoint?.lon ?? focus?.lon ?? yaoundeCenterLon,
                  initialZoom: (firstCheckpoint != null || focus != null)
                      ? 14
                      : 12.5,
                  alwaysShowMyLocation: _isItineraryMode,
                ),
              ),
              if (_isItineraryMode && checkpoints.isNotEmpty)
                Positioned(
                  top: topInset,
                  left: 16,
                  right: 88,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _progressPill(l10n, visitedCount, checkpoints.length),
                      const SizedBox(height: 8),
                      _nextStopPill(l10n),
                    ],
                  ),
                )
              else if (!_isItineraryMode && _route != null)
                // Browsing mode's equivalent of the itinerary pills above -
                // a computed route's headline distance/time used to be
                // visible only inside the collapsed options panel, so
                // closing the panel to look at the map lost the result
                // entirely. Mirrors _nextStopPill's own reasoning.
                Positioned(
                  top: topInset,
                  left: 16,
                  right: 88,
                  child: _routeSummaryPill(l10n),
                ),
              Positioned(
                top: topInset,
                right: 16,
                child: _panelToggleButton(l10n),
              ),
              if (_panelExpanded)
                Positioned(
                  top: topInset + 56,
                  left: 16,
                  right: 16,
                  child: _optionsPanel(l10n, withCoords, checkpoints),
                ),
              // Stacked above the locate-me button (which TripMap itself
              // pins at left:12, bottom:12) - same collapsed-button/
              // expanding-panel language as the top-right route toggle, so
              // both "hides a panel behind a circular button" controls on
              // this screen read as one consistent pattern.
              Positioned(
                left: 12,
                bottom: 78,
                child: AmenitiesToggleButton(
                  active: _amenitiesEnabled,
                  onTap: () {
                    setState(
                      () => _amenitiesLegendExpanded = !_amenitiesLegendExpanded,
                    );
                  },
                ),
              ),
              if (_amenitiesLegendExpanded)
                Positioned(
                  left: 12,
                  bottom: 132,
                  child: SizedBox(
                    width: 230,
                    child: AmenitiesLegendPanel(
                      enabled: _amenitiesEnabled,
                      onEnabledChanged: (value) {
                        setState(() => _amenitiesEnabled = value);
                        if (value) unawaited(_refreshAmenities(force: true));
                      },
                      enabledCategories: _enabledAmenityCategories,
                      onCategoryToggle: (category) {
                        setState(() {
                          if (_enabledAmenityCategories.contains(category)) {
                            _enabledAmenityCategories.remove(category);
                          } else {
                            _enabledAmenityCategories.add(category);
                          }
                        });
                      },
                      showEmptyHint:
                          _amenitiesEnabled &&
                          _amenitiesFetchedOnce &&
                          _amenities.isEmpty,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _panelToggleButton(AppLocalizations l10n) {
    final button = Material(
      color: _panelExpanded
          ? Theme.of(context).colorScheme.primary
          : const Color(0xFF0B1A24),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _panelExpanded = !_panelExpanded),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            _panelExpanded ? Icons.close : Icons.tune,
            color: Colors.white,
            size: 20,
            semanticLabel: l10n.mapOptionsToggleTooltip,
          ),
        ),
      ),
    );
    // A quiet cue that a route result is parked behind this tap, since
    // closing the panel to look at the map otherwise gives no hint that
    // there's something worth reopening it for.
    if (_panelExpanded || _route == null) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
              border: Border.all(color: const Color(0xFF0B1A24), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressPill(AppLocalizations l10n, int visited, int total) {
    return GlassPanel(
      style: GlassPanelStyle.solid,
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_circle, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            l10n.mapItineraryProgress(visited, total),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // The always-visible "how far to my next stop" pill - the one figure
  // worth surfacing without opening the details panel, since it's what
  // actually answers "should I keep going this way" while mid-route. Sits
  // right under the progress pill; shows nothing once there's no next leg
  // to report (route still loading for the first time, or every stop has
  // already been reached).
  Widget _nextStopPill(AppLocalizations l10n) {
    final nextLeg = _route?.legs.isNotEmpty == true ? _route!.legs.first : null;
    if (_remainingCheckpoints.isEmpty && _visitedIds.isNotEmpty) {
      return GlassPanel(
        style: GlassPanelStyle.solid,
        borderRadius: BorderRadius.circular(999),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              l10n.mapItineraryCompleteLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }
    if (nextLeg == null) return const SizedBox.shrink();
    return GlassPanel(
      style: GlassPanelStyle.solid,
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            l10n.mapNextStopSummary(
              _formatDistance(nextLeg.distanceMeters),
              formatDuration(Duration(seconds: nextLeg.durationSeconds.round())),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // Browsing-mode counterpart of _nextStopPill - the computed route's
  // headline distance/time, always visible even with the options panel
  // collapsed.
  Widget _routeSummaryPill(AppLocalizations l10n) {
    final route = _route;
    if (route == null) return const SizedBox.shrink();
    return GlassPanel(
      style: GlassPanelStyle.solid,
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            _formatDistance(route.distanceMeters),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.schedule, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            formatDuration(Duration(seconds: route.durationSeconds.round())),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsPanel(
    AppLocalizations l10n,
    List<Destination> withCoords,
    List<Destination> checkpoints,
  ) {
    return GlassPanel(
      style: GlassPanelStyle.solid,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(14),
      // Pinned on top+left+right but not bottom (see the Positioned above),
      // so its height constraint is unbounded - without `min` a Column
      // defaults to trying to be as tall as possible, which fails to lay
      // out under an infinite max height and renders nothing at all.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isItineraryMode
                      ? (_itineraryTitle ?? l10n.navMap)
                      : l10n.mapTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_isItineraryMode)
                TextButton(
                  onPressed: _leaveItineraryMode,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.mapLeaveItineraryButton,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                )
              else if (_origin != null || _destination != null)
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
          if (_isItineraryMode) ...[
            _buildItinerarySummary(l10n, checkpoints),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _selectItinerary,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: Colors.white70,
                ),
                label: Text(
                  l10n.mapSelectItineraryButton,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ),
            ),
          ] else ...[
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
                        onPicked: (d) => setState(() => _origin = d),
                        allowMyLocation: true,
                      ),
                      const SizedBox(height: 8),
                      _pointField(
                        icon: Icons.flag,
                        label: l10n.mapToLabel,
                        value: _destination,
                        options: withCoords,
                        onPicked: (d) => setState(() => _destination = d),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: (_origin == null && _destination == null)
                      ? null
                      : _swapPoints,
                  icon: const Icon(Icons.swap_vert, color: Colors.white70),
                  tooltip: l10n.mapSwapButton,
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _selectItinerary,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route, size: 18, color: Colors.white70),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.mapSelectItineraryButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          // Separates "what you're choosing" (inputs above) from "what you
          // got" (results below) - only drawn when there's actually a
          // result/status to separate from, not as permanent clutter.
          if (_routeLoading || _routeError != null || _route != null) ...[
            const SizedBox(height: 10),
            Divider(color: context.tripColors.glassBorder, height: 1),
          ],
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
              _routeErrorMessage(l10n),
              style: TextStyle(color: Colors.red.shade100, fontSize: 12.5),
            ),
            // Not shown for "not configured"/"no route found" - those are
            // problems retrying the exact same request can't fix, unlike
            // the routing provider's own transient failures/rate limits (or
            // a since-refreshed GPS fix, for the too-far case).
            if (_canRetryRoute) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _computeRoute,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.mapRetryButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (_route != null) ...[
            const SizedBox(height: 10),
            if (_isItineraryMode) ...[
              Text(
                l10n.mapRemainingLabel,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                const Icon(Icons.straighten, size: 15, color: Colors.white70),
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
                const Icon(Icons.schedule, size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  formatDuration(
                    Duration(seconds: _route!.durationSeconds.round()),
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
    );
  }
}
