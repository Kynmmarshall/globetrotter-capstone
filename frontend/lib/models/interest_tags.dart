import 'package:flutter/material.dart';

/// The exact set of tags used across Yaoundé destinations in the backend
/// (trip_io_backend/data/data.json). Kept in sync manually - these are
/// also what /recommendations matches a user's interests against, so the
/// picker here must use the same vocabulary or matching silently breaks.
const List<String> interestTags = [
  'architecture',
  'art',
  'culture',
  'entertainment',
  'events',
  'family',
  'food',
  'hiking',
  'history',
  'landmark',
  'monument',
  'museum',
  'nature',
  'religion',
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
  'culture': Icons.theater_comedy,
  'entertainment': Icons.celebration,
  'events': Icons.event,
  'family': Icons.family_restroom,
  'food': Icons.restaurant,
  'hiking': Icons.hiking,
  'history': Icons.history_edu,
  'landmark': Icons.location_city,
  'monument': Icons.fort,
  'museum': Icons.museum,
  'nature': Icons.nature,
  'religion': Icons.church,
  'shopping': Icons.storefront,
  'sports': Icons.sports_soccer,
  'viewpoint': Icons.landscape,
  'wildlife': Icons.cruelty_free,
};

IconData interestTagIcon(String tag) => interestTagIcons[tag] ?? Icons.sell;
