import 'package:url_launcher/url_launcher.dart';

/// Our own source label for this integration - shown to Yango as
/// attribution for opens coming from trip_io.
const String yangoRefId = 'trip_io';

/// Builds a Yango ride-order page URL pre-filled with a pickup and
/// destination point. Confirmed live: yango.com/en_int/order/ is a plain
/// web page (HTTP 200, sets its own locale/country cookies), not an Adjust
/// dynamic link like yango.go.link/route - it needs no partner tracker
/// token to resolve, and renders Yango's own order flow directly with the
/// route already filled in rather than bouncing through an app-store
/// fallback page. Coordinates are longitude,latitude (confirmed against
/// known Yaoundé coordinates - lon ~11.5, lat ~3.85 - matching gfrom/gto's
/// order).
Uri buildYangoRouteUri({
  required double pickupLat,
  required double pickupLon,
  required double destLat,
  required double destLon,
}) {
  return Uri.https('yango.com', '/en_int/order/', {
    'gfrom': '$pickupLon,$pickupLat',
    'gto': '$destLon,$destLat',
    'ref': yangoRefId,
  });
}

Future<bool> launchYangoRoute({
  required double pickupLat,
  required double pickupLon,
  required double destLat,
  required double destLon,
}) {
  final uri = buildYangoRouteUri(
    pickupLat: pickupLat,
    pickupLon: pickupLon,
    destLat: destLat,
    destLon: destLon,
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
