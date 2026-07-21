import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/models/models.dart';

class SessionController extends ChangeNotifier {
  static const _tokenKey = 'gt_token';
  static const _usernameKey = 'gt_username';
  static const _emailKey = 'gt_email';
  static const _avatarPathKey = 'gt_avatar_path';
  static const _bioKey = 'gt_bio';
  static const _memberSinceKey = 'gt_member_since';
  static const _localeKey = 'gt_locale';

  bool _ready = false;
  bool _loading = false;
  String? _error;
  String? _token;
  String? _username;
  String? _email;
  String? _avatarPath;
  String? _bio;
  DateTime? _memberSince;
  Locale? _locale;

  bool get ready => _ready;
  bool get isLoading => _loading;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;
  String? get error => _error;
  String? get username => _username;
  String? get email => _email;
  String? get avatarPath => _avatarPath;
  String? get bio => _bio;
  DateTime? get memberSince => _memberSince;
  // Null means "follow the device's system language".
  Locale? get locale => _locale;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _email = prefs.getString(_emailKey);
    _avatarPath = prefs.getString(_avatarPathKey);
    _bio = prefs.getString(_bioKey);
    final memberSinceRaw = prefs.getString(_memberSinceKey);
    _memberSince = memberSinceRaw != null
        ? DateTime.tryParse(memberSinceRaw)
        : null;
    final localeCode = prefs.getString(_localeKey);
    _locale = localeCode != null ? Locale(localeCode) : null;
    _ready = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
    _locale = locale;
    notifyListeners();
  }

  Future<void> register(
    String username,
    String password, {
    String? email,
  }) async {
    await _runGuarded(() async {
      final token = await ApiClient().register(
        username,
        password,
        email: email,
      );
      await _saveAuth(token, username, email: email, isNewAccount: true);
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

  Future<void> updateBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bioKey, bio);
    _bio = bio;
    notifyListeners();
  }

  Future<void> updateAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPathKey, path);
    _avatarPath = path;
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

  Future<Itinerary> createItinerary(
    String title,
    List<String> destinations, {
    List<ScheduleEntry>? schedule,
  }) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient().createItinerary(
      token,
      title,
      destinations,
      schedule: schedule,
    );
  }

  Future<List<Itinerary>> itineraries() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    return ApiClient().getItineraries(token);
  }

  Future<void> _saveAuth(
    String token,
    String username, {
    String? email,
    bool isNewAccount = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    _token = token;
    _username = username;
    _error = null;

    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString(_emailKey, email.trim());
      _email = email.trim();
    }

    if (isNewAccount || _memberSince == null) {
      final now = DateTime.now();
      await prefs.setString(_memberSinceKey, now.toIso8601String());
      _memberSince = now;
    }
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
