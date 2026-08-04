import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/map_page.dart';
import 'package:trip_io/services/session_controller.dart';

/// A tappable "directions" icon, meant to sit on top of a destination card
/// or in a detail page header - same slot pattern as [FavoriteToggleButton]
/// and [AddToItineraryButton]. Tapping it opens the map already routing
/// from the device's current location to [destination], instead of leaving
/// the user to fill in the From/To fields themselves.
class DirectionsButton extends StatelessWidget {
  const DirectionsButton({
    super.key,
    required this.session,
    required this.destination,
    this.size = 20,
  });

  final SessionController session;
  final Destination destination;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MapPage(
            session: session,
            showAppBar: true,
            focusDestination: destination,
            directionsFromMyLocation: true,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.directions,
          color: Colors.white,
          size: size,
          semanticLabel: l10n.directionsButtonTooltip,
        ),
      ),
    );
  }
}
