import 'package:flutter/material.dart';

import 'package:trip_io/l10n/gen/app_localizations.dart';

/// The fixed set of nearby-amenity categories the backend's GET /amenities
/// can return (see trip_io_backend/services/recommendation_service/app/
/// amenities.py's CATEGORY_TAGS) - kept in the same order they're shown in
/// the map legend.
const List<String> amenityCategories = [
  'hospital',
  'pharmacy',
  'fuel',
  'hotel',
  'bank_atm',
  'police',
];

/// icon + color per category - deliberately distinct from every other color
/// already meaningful on the map (route blue, my-location green, selected
/// amber, unselected teal - see trip_map_maplibre.dart/themes/trip_colors.dart)
/// so a legend dot is never confused with something else on screen.
const Map<String, IconData> amenityCategoryIcons = {
  'hospital': Icons.local_hospital,
  'pharmacy': Icons.local_pharmacy,
  'fuel': Icons.local_gas_station,
  'hotel': Icons.hotel,
  'bank_atm': Icons.local_atm,
  'police': Icons.local_police,
};

const Map<String, Color> amenityCategoryColors = {
  'hospital': Color(0xFFE53935),
  'pharmacy': Color(0xFFD81B60),
  'fuel': Color(0xFF8E24AA),
  'hotel': Color(0xFF5C6BC0),
  'bank_atm': Color(0xFF6D4C41),
  'police': Color(0xFF37474F),
};

IconData amenityCategoryIcon(String category) =>
    amenityCategoryIcons[category] ?? Icons.place;

Color amenityCategoryColor(String category) =>
    amenityCategoryColors[category] ?? Colors.grey;

String amenityCategoryLabel(String category, AppLocalizations l10n) {
  switch (category) {
    case 'hospital':
      return l10n.mapAmenityCategoryHospital;
    case 'pharmacy':
      return l10n.mapAmenityCategoryPharmacy;
    case 'fuel':
      return l10n.mapAmenityCategoryFuel;
    case 'hotel':
      return l10n.mapAmenityCategoryHotel;
    case 'bank_atm':
      return l10n.mapAmenityCategoryBankAtm;
    case 'police':
      return l10n.mapAmenityCategoryPolice;
    default:
      return category;
  }
}
