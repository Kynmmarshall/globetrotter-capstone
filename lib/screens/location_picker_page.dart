import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/widgets/trip_map.dart';

/// Full-screen "tap the map to set a point" picker - used by the suggest-
/// destination form to let a user indicate a real position instead of only
/// typing a free-text location string. Pops with the picked (lat, lon), or
/// null if dismissed without confirming.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initialLat, this.initialLon});

  final double? initialLat;
  final double? initialLon;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  double? _lat;
  double? _lon;
  bool _locating = false;

  // TripMap only reads initialLat/initialLon once, at construction - bumping
  // this and keying TripMap on it forces a fresh instance (and so a fresh
  // camera position) whenever "go to my location" jumps somewhere new,
  // rather than just moving the marker under an unmoved viewport.
  int _mapEpoch = 0;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lon = widget.initialLon;
  }

  void _confirm() {
    final lat = _lat;
    final lon = _lon;
    if (lat == null || lon == null) return;
    Navigator.of(context).pop((lat: lat, lon: lon));
  }

  Future<void> _goToMyLocation() async {
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
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lon = position.longitude;
        _mapEpoch++;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPoint = _lat != null && _lon != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pickLocationTitle),
        actions: [
          IconButton(
            onPressed: _locating ? null : _goToMyLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            tooltip: l10n.mapUseMyLocation,
          ),
          IconButton(
            onPressed: hasPoint ? _confirm : null,
            icon: const Icon(Icons.check),
            tooltip: l10n.pickLocationConfirm,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.pickLocationHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: TripMap(
              key: ValueKey(_mapEpoch),
              markers: hasPoint
                  ? [
                      TripMapMarker(
                        id: 'picked',
                        name: '',
                        lat: _lat!,
                        lon: _lon!,
                        selected: true,
                      ),
                    ]
                  : const [],
              initialLat: _lat ?? yaoundeCenterLat,
              initialLon: _lon ?? yaoundeCenterLon,
              initialZoom: hasPoint ? 14 : 12.5,
              onMapTapped: (lat, lon) => setState(() {
                _lat = lat;
                _lon = lon;
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: hasPoint
          ? FloatingActionButton.extended(
              onPressed: _confirm,
              icon: const Icon(Icons.check),
              label: Text(l10n.pickLocationConfirm),
            )
          : null,
    );
  }
}
