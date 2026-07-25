/// The exact set of tags used across Yaoundé destinations in the backend
/// (trip_io_backend/data/data.json). Kept in sync manually - these are
/// also what /recommendations matches a user's interests against, so the
/// picker here must use the same vocabulary or matching silently breaks.
const List<String> interestTags = [
  'architecture',
  'art',
  'culture',
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
  'viewpoint',
  'wildlife',
];
