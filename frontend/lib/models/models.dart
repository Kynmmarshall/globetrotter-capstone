/// A real, verified restaurant or hotel near a destination - not
/// generated content. See trip_io_backend/data/data.json.
class NearbyPlace {
  NearbyPlace({
    required this.name,
    required this.category,
    this.description,
    this.tags = const [],
    this.location,
  });

  final String name;
  final String category; // "hotel" | "restaurant"
  final String? description;
  final List<String> tags;
  final String? location;

  bool get isHotel => category == 'hotel';

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: json['description']?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList(),
      location: json['location']?.toString(),
    );
  }
}

class Destination {
  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.tags,
    this.imageUrl,
    this.description,
    this.location,
    this.lat,
    this.lon,
    this.nearby = const [],
    this.openingHours,
    this.entryFee,
    this.tips,
    this.status = 'approved',
    this.submittedBy,
    this.ratingAverage,
    this.ratingCount = 0,
    this.userRating,
    this.commentCount = 0,
  });

  final String id;
  final String name;
  final String country;
  final List<String> tags;
  final String? imageUrl;
  final String? description;
  final String? location;
  final double? lat;
  final double? lon;
  final List<NearbyPlace> nearby;
  final String? openingHours;
  final String? entryFee;
  final String? tips;
  final String status; // "approved" | "pending" | "rejected"
  final String? submittedBy;
  final double? ratingAverage;
  final int ratingCount;
  final int? userRating; // 1-5, this viewer's own rating if any
  final int commentCount; // total comments + replies

  /// Whether the backend supplied enough content to show this as a
  /// featured, photo-led card rather than a plain search result.
  bool get isFeatured => (imageUrl ?? '').isNotEmpty;

  bool get hasRatings => ratingCount > 0 && ratingAverage != null;

  bool get hasCoordinates => lat != null && lon != null;

  factory Destination.fromJson(Map<String, dynamic> json) {
    final rawTags = (json['tags'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    String? optionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      final str = value.toString();
      return str.isEmpty ? null : str;
    }

    return Destination(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      tags: rawTags,
      imageUrl: optionalString('image_url'),
      description: optionalString('description'),
      location: optionalString('location'),
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      nearby: (json['nearby'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => NearbyPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
      openingHours: optionalString('opening_hours'),
      entryFee: optionalString('entry_fee'),
      tips: optionalString('tips'),
      status: (json['status'] ?? 'approved').toString(),
      submittedBy: optionalString('submitted_by'),
      ratingAverage: (json['rating_average'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      userRating: (json['user_rating'] as num?)?.toInt(),
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns a copy with just the rating fields replaced - used after
  /// rating/un-rating to update a single card in place.
  Destination withRating({double? ratingAverage, required int ratingCount, int? userRating}) {
    return Destination(
      id: id,
      name: name,
      country: country,
      tags: tags,
      imageUrl: imageUrl,
      description: description,
      location: location,
      lat: lat,
      lon: lon,
      nearby: nearby,
      openingHours: openingHours,
      entryFee: entryFee,
      tips: tips,
      status: status,
      submittedBy: submittedBy,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      userRating: userRating,
      commentCount: commentCount,
    );
  }
}

/// A single turn in an AI assistant conversation. `role` is "user" or
/// "assistant" - mirrors the backend's ChatMessage schema.
class ChatMessage {
  ChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: (json['role'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }
}

class UserProfile {
  UserProfile({
    required this.username,
    this.email,
    this.interests = const [],
    this.avatarUrl,
    this.favoriteIds = const [],
    this.role,
  });

  final String username;
  final String? email;
  final List<String> interests;
  final String? avatarUrl;
  final List<String> favoriteIds;
  final String? role; // "user" | "admin"

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: (json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      interests: (json['interests'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList(),
      avatarUrl: json['avatar_url']?.toString(),
      favoriteIds: (json['favorite_ids'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList(),
      role: json['role']?.toString(),
    );
  }
}

/// A single timed stop in an auto-generated itinerary plan: visit
/// [destinationId] from [start] to [end].
class ScheduleEntry {
  ScheduleEntry({
    required this.destinationId,
    required this.start,
    required this.end,
  });

  final String destinationId;
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() => {
    'destination_id': destinationId,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  static ScheduleEntry? fromJson(Map<String, dynamic> json) {
    final start = DateTime.tryParse((json['start'] ?? '').toString());
    final end = DateTime.tryParse((json['end'] ?? '').toString());
    final destinationId = (json['destination_id'] ?? '').toString();
    if (start == null || end == null || destinationId.isEmpty) {
      return null;
    }
    return ScheduleEntry(destinationId: destinationId, start: start, end: end);
  }
}

class Itinerary {
  Itinerary({
    required this.id,
    required this.user,
    required this.title,
    required this.destinations,
    this.schedule = const [],
    this.startDate,
    this.endDate,
  });

  final String id;
  final String user;
  final String title;
  final List<String> destinations;
  final List<ScheduleEntry> schedule;
  final DateTime? startDate;
  final DateTime? endDate;

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['schedule'] as List<dynamic>?;
    return Itinerary(
      id: (json['id'] ?? '').toString(),
      user: (json['user'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      destinations: (json['destinations'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      schedule: (rawSchedule ?? <dynamic>[])
          .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
          .whereType<ScheduleEntry>()
          .toList(),
      startDate: DateTime.tryParse((json['start_date'] ?? '').toString()),
      endDate: DateTime.tryParse((json['end_date'] ?? '').toString()),
    );
  }
}

/// A comment (or reply, via [parentId]) on a destination. [replies] nests
/// arbitrarily deep, matching the backend's unlimited-depth thread tree.
class Comment {
  Comment({
    required this.id,
    required this.destinationId,
    this.parentId,
    required this.username,
    required this.text,
    required this.createdAt,
    required this.score,
    this.userVote,
    this.replies = const [],
  });

  final String id;
  final String destinationId;
  final String? parentId;
  final String username;
  final String text;
  final DateTime? createdAt;
  final int score;
  final String? userVote; // "up" | "down" | null

  /// Mutable so the UI can splice in an updated node (new score/vote, a
  /// freshly posted reply) without refetching and rebuilding the whole tree.
  List<Comment> replies;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] ?? '').toString(),
      destinationId: (json['destination_id'] ?? '').toString(),
      parentId: json['parent_id']?.toString(),
      username: (json['username'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      score: (json['score'] as num?)?.toInt() ?? 0,
      userVote: json['user_vote']?.toString(),
      replies: (json['replies'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns a copy of this comment with vote fields replaced - used after
  /// voting, to update just the affected node in-place in a local tree.
  Comment withVote({required int score, required String? userVote}) {
    return Comment(
      id: id,
      destinationId: destinationId,
      parentId: parentId,
      username: username,
      text: text,
      createdAt: createdAt,
      score: score,
      userVote: userVote,
      replies: replies,
    );
  }

  /// Returns a copy with the text replaced - used after a successful edit,
  /// same in-place-splice pattern as [withVote].
  Comment withText(String text) {
    return Comment(
      id: id,
      destinationId: destinationId,
      parentId: parentId,
      username: username,
      text: text,
      createdAt: createdAt,
      score: score,
      userVote: userVote,
      replies: replies,
    );
  }
}

/// A single point along a route's geometry - mirrors the backend's
/// RouteWaypoint schema, also used for the origin/destination waypoints
/// sent to POST /route.
class RouteWaypoint {
  const RouteWaypoint({required this.lat, required this.lon});

  final double lat;
  final double lon;

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}

/// The result of a POST /route call: the full path geometry to draw, plus
/// trip totals - mirrors the backend's RouteResponse schema.
class RouteResult {
  const RouteResult({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<RouteWaypoint> geometry;
  final double distanceMeters;
  final double durationSeconds;

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      geometry: (json['geometry'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => RouteWaypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      durationSeconds: (json['duration_seconds'] as num).toDouble(),
    );
  }
}
