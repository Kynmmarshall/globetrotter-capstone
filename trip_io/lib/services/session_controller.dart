import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/models/models.dart';

class SessionController extends ChangeNotifier {
  static const _tokenKey = 'gt_token';
  static const _usernameKey = 'gt_username';

  bool _ready = false;
  bool _loading = false;
  String? _error;
  String? _token;
  String? _username;

  bool get ready => _ready;
  bool get isLoading => _loading;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;
  String? get error => _error;
  String? get username => _username;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _ready = true;
    notifyListeners();
  }

  Future<void> register(String username, String password, {String? email}) async {
    await _runGuarded(() async {
      final token = await ApiClient().register(username, password, email: email);
      await _saveAuth(token, username);
    });
  }

  Future<void> login(String username, String password) async {
    await _runGuarded(() async {
      final token = await ApiClient().login(username, password);
      await _saveAuth(token, username);
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    _token = null;
    _username = null;
    _error = null;
    notifyListeners();
  }

  Future<List<Destination>> destinations({String? query}) {
    return ApiClient().getDestinations(query: query);
  }

  Future<List<Destination>> recommendations() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient().getRecommendations(token);
  }

  Future<Itinerary> createItinerary(String title, List<String> destinations) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient().createItinerary(token, title, destinations);
  }

  Future<List<Itinerary>> itineraries() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient().getItineraries(token);
  }

  Future<void> _saveAuth(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    _token = token;
    _username = username;
    _error = null;
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
