import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  ApiClient(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(queryParameters: queryParameters);
  }

  Future<String> register(String username, String password) async {
    final response = await _client.post(
      _uri('/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
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
    final response = await _client.get(_uri('/destinations', query != null && query.isNotEmpty ? {'q': query} : null));
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Destination.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Destination>> getRecommendations(String token) async {
    final response = await _client.get(
      _uri('/recommendations'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Destination.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Itinerary> createItinerary(String token, String title, List<String> destinations) async {
    final response = await _client.post(
      _uri('/itineraries'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'destinations': destinations}),
    );
    _throwIfNotOk(response);
    return Itinerary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Itinerary>> getItineraries(String token) async {
    final response = await _client.get(
      _uri('/itineraries'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Itinerary.fromJson(e as Map<String, dynamic>)).toList();
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
