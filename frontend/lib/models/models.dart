class Destination {
  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.tags,
    this.imageUrl,
    this.description,
    this.location,
  });

  final String id;
  final String name;
  final String country;
  final List<String> tags;
  final String? imageUrl;
  final String? description;
  final String? location;

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
  });

  final String id;
  final String user;
  final String title;
  final List<String> destinations;
  final List<ScheduleEntry> schedule;

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
    );
  }
}
