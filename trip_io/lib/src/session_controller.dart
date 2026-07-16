import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  static const _tokenKey = 'gt_token';
  static const _usernameKey = 'gt_username';
  static const _baseUrlKey = 'gt_base_url';

  bool _ready = false;
  bool _loading = false;
  String? _error;
  String? _token;
  String? _username;
  late String _baseUrl;

  bool get ready => _ready;
  bool get isLoading => _loading;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;
  String? get error => _error;
  String? get username => _username;
  String get baseUrl => _baseUrl;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _baseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl();
    _ready = true;
    notifyListeners();
  }

  Future<void> updateBaseUrl(String value) async {
    _baseUrl = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    await _runGuarded(() async {
      final token = await ApiClient(_baseUrl).register(username, password);
      await _saveAuth(token, username);
    });
  }

  Future<void> login(String username, String password) async {
    await _runGuarded(() async {
      final token = await ApiClient(_baseUrl).login(username, password);
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
    return ApiClient(_baseUrl).getDestinations(query: query);
  }

  Future<List<Destination>> recommendations() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient(_baseUrl).getRecommendations(token);
  }

  Future<Itinerary> createItinerary(String title, List<String> destinations) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient(_baseUrl).createItinerary(token, title, destinations);
  }

  Future<List<Itinerary>> itineraries() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient(_baseUrl).getItineraries(token);
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

  String _defaultBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
