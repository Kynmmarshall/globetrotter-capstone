import 'package:flutter/material.dart';

/// The exact set of tags used across Yaoundé destinations in the backend
/// (trip_io_backend/data/data.json). Kept in sync manually - these are
/// also what /recommendations matches a user's interests against, so the
/// picker here must use the same vocabulary or matching silently breaks.
const List<String> interestTags = [
  'architecture',
  'art',
  'bar',
  'cafe',
  'culture',
  'entertainment',
  'events',
  'family',
  'fitness',
  'food',
  'golf',
  'hiking',
  'history',
  'hotel',
  'landmark',
  'monument',
  'museum',
  'nature',
  'nightlife',
  'religion',
  'restaurant',
  'shopping',
  'sports',
  'viewpoint',
  'wildlife',
];

/// One representative icon per tag, purely decorative (picker UI only -
/// never sent to the backend). Falls back to a generic tag icon for
/// anything not listed here, so a future addition to interestTags above
/// doesn't need a matching entry here to avoid breaking.
const Map<String, IconData> interestTagIcons = {
  'architecture': Icons.account_balance,
  'art': Icons.palette,
  'bar': Icons.local_bar,
  'cafe': Icons.local_cafe,
  'culture': Icons.theater_comedy,
  'entertainment': Icons.celebration,
  'events': Icons.event,
  'family': Icons.family_restroom,
  'fitness': Icons.fitness_center,
  'food': Icons.restaurant,
  'golf': Icons.golf_course,
  'hiking': Icons.hiking,
  'history': Icons.history_edu,
  'hotel': Icons.hotel,
  'landmark': Icons.location_city,
  'monument': Icons.fort,
  'museum': Icons.museum,
  'nature': Icons.nature,
  'nightlife': Icons.nightlife,
  'religion': Icons.church,
  'restaurant': Icons.restaurant_menu,
  'shopping': Icons.storefront,
  'sports': Icons.sports_soccer,
  'viewpoint': Icons.landscape,
  'wildlife': Icons.cruelty_free,
};

IconData interestTagIcon(String tag) => interestTagIcons[tag] ?? Icons.sell;
