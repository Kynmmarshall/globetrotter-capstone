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
    this.nearby = const [],
    this.openingHours,
    this.entryFee,
    this.tips,
  });

  final String id;
  final String name;
  final String country;
  final List<String> tags;
  final String? imageUrl;
  final String? description;
  final String? location;
  final List<NearbyPlace> nearby;
  final String? openingHours;
  final String? entryFee;
  final String? tips;

  /// Whether the backend supplied enough content to show this as a
  /// featured, photo-led card rather than a plain search result.
  bool get isFeatured => (imageUrl ?? '').isNotEmpty;

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
      nearby: (json['nearby'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => NearbyPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
      openingHours: optionalString('opening_hours'),
      entryFee: optionalString('entry_fee'),
      tips: optionalString('tips'),
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
}

class UserProfile {
  UserProfile({required this.username, this.email, this.interests = const []});

  final String username;
  final String? email;
  final List<String> interests;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: (json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      interests: (json['interests'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList(),
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
