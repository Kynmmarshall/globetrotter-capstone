import 'dart:convert';

import 'package:http/http.dart' as http;
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

  Future<String> register(
    String username,
    String password, {
    String? email,
  }) async {
    final response = await _client.post(
      _uri('/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
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

  Future<List<Destination>> getDestinations({String? query}) async {
    final response = await _client.get(
      _uri(
        '/destinations',
        query != null && query.isNotEmpty ? {'q': query} : null,
      ),
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
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
  }) async {
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
