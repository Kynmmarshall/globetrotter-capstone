import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:trip_io/models/models.dart';

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
    : _baseUrl = (baseUrl ?? _defaultBaseUrl()).trim(),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  // Defaults to the deployed backend so `flutter run`/builds work against
  // the real API out of the box. Override for local backend testing with
  // --dart-define=API_BASE_URL=http://localhost:8000 (or 10.0.2.2 on the
  // Android emulator).
  static String _defaultBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return 'https://trip-io.duckdns.org';
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse(
      '$normalizedBase$path',
    ).replace(queryParameters: queryParameters);
  }

  /// Resolves a backend-relative path (e.g. an `image_url` like
  /// `/static/destinations/x.png`) into an absolute URL against the same
  /// API host the app is configured to talk to. Already-absolute URLs are
  /// returned unchanged.
  static String? resolveAssetUrl(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = _defaultBaseUrl();
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }

  /// Builds the shareable link for an itinerary - opens this same Flutter
  /// web app (served at `/app/` by the Gateway) with a `claim` query param
  /// the app reads on startup (see `app.dart`) to copy the shared
  /// itinerary straight into whoever opens the link's own account,
  /// prompting them to create one first if they don't have one yet.
  /// Deliberately not a bare preview page - the point of the link is to
  /// get the trip into the recipient's own account, not just show it to
  /// them.
  static String resolveShareUrl(String shareToken) {
    final base = _defaultBaseUrl();
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$normalizedBase/app/?claim=$shareToken';
  }

  Future<String> register(
    String username,
    String password, {
    String? email,
    List<String>? interests,
  }) async {
    final response = await _client.post(
      _uri('/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (interests != null && interests.isNotEmpty) 'interests': interests,
      }),
    );
    return _extractToken(response);
  }

  Future<String> login(String username, String password) async {
    final response = await _client.post(
      _uri('/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _extractToken(response);
  }

  Future<String> googleAuth(String idToken) async {
    final response = await _client.post(
      _uri('/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    return _extractToken(response);
  }

  Future<void> requestPasswordReset(String identifier) async {
    final response = await _client.post(
      _uri('/auth/request-password-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );
    _throwIfNotOk(response);
  }

  Future<void> resetPassword(
    String identifier,
    String code,
    String newPassword,
  ) async {
    final response = await _client.post(
      _uri('/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'code': code,
        'new_password': newPassword,
      }),
    );
    _throwIfNotOk(response);
  }

  Future<UserProfile> getProfile(String token) async {
    final response = await _client.get(
      _uri('/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // The backend keys off the multipart part's actual Content-Type header
  // (not the filename) to decide whether to accept the image, so this has
  // to be inferred and set explicitly - MultipartFile.fromBytes defaults to
  // application/octet-stream, which the backend would reject outright.
  static MediaType _imageMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  Future<UserProfile> uploadAvatar(
    String token,
    List<int> bytes,
    String filename,
  ) async {
    final request = http.MultipartRequest('POST', _uri('/me/avatar'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: _imageMediaType(filename),
        ),
      );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _throwIfNotOk(response);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProfile> updateInterests(
    String token,
    List<String> interests,
  ) async {
    final response = await _client.put(
      _uri('/me/interests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'interests': interests}),
    );
    _throwIfNotOk(response);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Destination>> getFavorites(String token) async {
    final response = await _client.get(
      _uri('/me/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> addFavorite(String token, String destinationId) async {
    final response = await _client.post(
      _uri('/me/favorites/$destinationId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProfile> removeFavorite(String token, String destinationId) async {
    final response = await _client.delete(
      _uri('/me/favorites/$destinationId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<AppNotification>> getNotifications(String token) async {
    final response = await _client.get(
      _uri('/me/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String token, String notificationId) async {
    final response = await _client.post(
      _uri('/me/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
  }

  Future<List<Destination>> getDestinations({
    String? query,
    String? token,
  }) async {
    final response = await _client.get(
      _uri(
        '/destinations',
        query != null && query.isNotEmpty ? {'q': query} : null,
      ),
      // Optional: /destinations works for anonymous callers too, but a
      // token lets the backend attach each destination's user_rating.
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Destination> getDestination(String destinationId, {String? token}) async {
    final response = await _client.get(
      _uri('/destinations/$destinationId'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
    _throwIfNotOk(response);
    return Destination.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Destination> rateDestination(
    String token,
    String destinationId,
    int stars,
  ) async {
    final response = await _client.put(
      _uri('/destinations/$destinationId/rating'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'stars': stars}),
    );
    _throwIfNotOk(response);
    return _destinationFromRatingSummary(response.body);
  }

  Future<Destination> clearRating(String token, String destinationId) async {
    final response = await _client.delete(
      _uri('/destinations/$destinationId/rating'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    return _destinationFromRatingSummary(response.body);
  }

  // The rating endpoints return a small RatingSummary, not a full
  // Destination - Destination.fromJson tolerates the missing fields fine
  // since everything but id/name/country/tags is optional, and the caller
  // only actually reads the rating fields off the result anyway.
  Destination _destinationFromRatingSummary(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return Destination.fromJson({
      'id': decoded['destination_id'],
      'name': '',
      'country': '',
      'tags': const [],
      'rating_average': decoded['rating_average'],
      'rating_count': decoded['rating_count'],
      'user_rating': decoded['user_rating'],
    });
  }

  Future<Destination> submitDestination(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      _uri('/destinations/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    _throwIfNotOk(response);
    return Destination.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Destination>> getMySubmissions(String token) async {
    final response = await _client.get(
      _uri('/me/submissions'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Destination> uploadDestinationImage(
    String token,
    String destinationId,
    List<int> bytes,
    String filename,
  ) async {
    final request =
        http.MultipartRequest(
            'POST',
            _uri('/destinations/$destinationId/image'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: filename,
              contentType: _imageMediaType(filename),
            ),
          );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _throwIfNotOk(response);
    return Destination.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Destination>> getRecommendations(String token) async {
    final response = await _client.get(
      _uri('/recommendations'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Itinerary> createItinerary(
    String token,
    String title,
    List<String> destinations, {
    List<ScheduleEntry>? schedule,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String dateOnly(DateTime d) => d.toIso8601String().split('T').first;
    final response = await _client.post(
      _uri('/itineraries'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'destinations': destinations,
        if (schedule != null)
          'schedule': schedule.map((e) => e.toJson()).toList(),
        if (startDate != null) 'start_date': dateOnly(startDate),
        if (endDate != null) 'end_date': dateOnly(endDate),
      }),
    );
    _throwIfNotOk(response);
    return Itinerary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Itinerary>> getItineraries(String token) async {
    final response = await _client.get(
      _uri('/itineraries'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Itinerary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Itinerary> updateItinerary(
    String token,
    String itineraryId, {
    String? title,
    List<String>? destinations,
    List<ScheduleEntry>? schedule,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) {
      body['title'] = title;
    }
    if (destinations != null) {
      body['destinations'] = destinations;
    }
    if (schedule != null) {
      body['schedule'] = schedule.map((e) => e.toJson()).toList();
    }
    final response = await _client.patch(
      _uri('/itineraries/$itineraryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    _throwIfNotOk(response);
    return Itinerary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteItinerary(String token, String itineraryId) async {
    final response = await _client.delete(
      _uri('/itineraries/$itineraryId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
  }

  Future<String> shareItinerary(String token, String itineraryId) async {
    final response = await _client.post(
      _uri('/itineraries/$itineraryId/share'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['share_token'] as String;
  }

  Future<void> unshareItinerary(String token, String itineraryId) async {
    final response = await _client.delete(
      _uri('/itineraries/$itineraryId/share'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
  }

  Future<Itinerary> claimSharedItinerary(String token, String shareToken) async {
    final response = await _client.post(
      _uri('/itineraries/claim/$shareToken'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    return Itinerary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<RouteResult> getRoute(
    String token,
    List<RouteWaypoint> waypoints, {
    String profile = 'driving-car',
  }) async {
    final response = await _client.post(
      _uri('/route'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'profile': profile,
      }),
    );
    _throwIfNotOk(response);
    return RouteResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<MapAmenity>> getAmenities({
    List<String>? categories,
    String? token,
  }) async {
    final response = await _client.get(
      _uri(
        '/amenities',
        categories != null && categories.isNotEmpty
            ? {'categories': categories.join(',')}
            : null,
      ),
      // Optional, like /destinations - amenities are public map data, but a
      // token is sent when available since every other map call already has
      // one handy.
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => MapAmenity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Comment>> getComments(String token, String destinationId) async {
    final response = await _client.get(
      _uri('/destinations/$destinationId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> postComment(
    String token,
    String destinationId,
    String text, {
    String? parentId,
  }) async {
    final response = await _client.post(
      _uri('/destinations/$destinationId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text, 'parent_id': ?parentId}),
    );
    _throwIfNotOk(response);
    return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Comment> editComment(
    String token,
    String commentId,
    String text,
  ) async {
    final response = await _client.patch(
      _uri('/comments/$commentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    _throwIfNotOk(response);
    return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteComment(String token, String commentId) async {
    final response = await _client.delete(
      _uri('/comments/$commentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
  }

  /// [direction] is "up", "down", or "none" (removes the vote).
  Future<Comment> voteComment(
    String token,
    String commentId,
    String direction,
  ) async {
    final response = await _client.post(
      _uri('/comments/$commentId/vote'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'direction': direction}),
    );
    _throwIfNotOk(response);
    return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<String> aiChat(
    String token,
    List<ChatMessage> messages, {
    String? languageCode,
  }) async {
    final response = await _client.post(
      _uri('/ai/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'messages': messages.map((m) => m.toJson()).toList(),
        if (languageCode != null && languageCode.isNotEmpty)
          'language_code': languageCode,
      }),
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['reply'] ?? '').toString();
  }

  Future<String> aiExplain(
    String token,
    String destinationId, {
    String? languageCode,
  }) async {
    final uri = _uri(
      '/ai/explain/$destinationId',
      languageCode != null && languageCode.isNotEmpty
          ? {'language_code': languageCode}
          : null,
    );
    final response = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['reply'] ?? '').toString();
  }

  String _extractToken(http.Response response) {
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['access_token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('No access token returned by server.');
    }
    return token;
  }

  void _throwIfNotOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = decoded['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        message = detail;
      }
    } catch (_) {
      // Keep default message if response body is not JSON.
    }
    throw Exception(message);
  }
}
