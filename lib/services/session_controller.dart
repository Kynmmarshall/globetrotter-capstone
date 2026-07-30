import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/models/models.dart';

class SessionController extends ChangeNotifier {
  static const _tokenKey = 'gt_token';
  static const _usernameKey = 'gt_username';
  static const _emailKey = 'gt_email';
  static const _avatarUrlKey = 'gt_avatar_url';
  static const _bioKey = 'gt_bio';
  static const _memberSinceKey = 'gt_member_since';
  static const _localeKey = 'gt_locale';
  static const _interestsKey = 'gt_interests';
  static const _favoriteIdsKey = 'gt_favorite_ids';

  bool _ready = false;
  bool _loading = false;
  String? _error;
  String? _token;
  String? _username;
  String? _email;
  String? _avatarUrl;
  String? _bio;
  DateTime? _memberSince;
  Locale? _locale;
  List<String> _interests = [];
  Set<String> _favoriteIds = {};

  bool get ready => _ready;
  bool get isLoading => _loading;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;
  String? get error => _error;
  String? get username => _username;
  String? get email => _email;
  String? get avatarUrl => _avatarUrl;
  String? get bio => _bio;
  DateTime? get memberSince => _memberSince;
  // Null means "follow the device's system language".
  Locale? get locale => _locale;
  List<String> get interests => _interests;
  bool isFavorite(String destinationId) => _favoriteIds.contains(destinationId);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _email = prefs.getString(_emailKey);
    _avatarUrl = prefs.getString(_avatarUrlKey);
    _bio = prefs.getString(_bioKey);
    final memberSinceRaw = prefs.getString(_memberSinceKey);
    _memberSince = memberSinceRaw != null
        ? DateTime.tryParse(memberSinceRaw)
        : null;
    final localeCode = prefs.getString(_localeKey);
    _locale = localeCode != null ? Locale(localeCode) : null;
    _interests = prefs.getStringList(_interestsKey) ?? [];
    _favoriteIds = (prefs.getStringList(_favoriteIdsKey) ?? []).toSet();
    // A token that expired while the app was closed (JWTs are valid for a
    // week - see auth.py) should never make it to a "logged in" screen -
    // clear it here rather than letting the first API call surface it as
    // an error.
    if (_token != null && _isTokenExpired(_token!)) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_usernameKey);
      _token = null;
      _username = null;
    }
    if ((_username ?? '').isNotEmpty) {
      Analytics.instance.setUser(_username);
    }
    _ready = true;
    notifyListeners();
  }

  // Decodes the JWT payload to read `exp` without verifying the signature -
  // that's the server's job. This only ever drives a *local* logout, so the
  // worst case for a malformed/unreadable token is a missed early logout,
  // not a security decision made on unverified data.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int) return false;
      return DateTime.now().toUtc().isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true));
    } catch (_) {
      return false;
    }
  }

  /// Returns the current token if present and not expired, otherwise clears
  /// the session (so the UI reactively falls back to AuthScreen) and throws.
  String _requireToken() {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }
    if (_isTokenExpired(token)) {
      unawaited(logout());
      throw Exception('Your session expired. Please sign in again.');
    }
    return token;
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
    List<String>? interests,
  }) async {
    await _runGuarded(() async {
      final token = await ApiClient().register(
        username,
        password,
        email: email,
        interests: interests,
      );
      await _saveAuth(token, username, email: email, interests: interests, isNewAccount: true);
    });
  }

  Future<void> login(String username, String password) async {
    await _runGuarded(() async {
      final token = await ApiClient().login(username, password);
      await _saveAuth(token, username);
      // Pull interests/email set on another device, if any - best-effort,
      // login shouldn't fail just because this sync call did.
      try {
        final profile = await ApiClient().getProfile(token);
        await _applyProfile(profile);
      } catch (_) {
        // Ignore - local state (if any) still stands.
      }
    });
  }

  Future<void> loginWithGoogle(String idToken) async {
    await _runGuarded(() async {
      final token = await ApiClient().googleAuth(idToken);
      // The backend assigns the username for Google accounts (derived from
      // the Google email/name), so unlike register()/login() we don't know
      // it up front - fetch the profile it just created/matched instead.
      final profile = await ApiClient().getProfile(token);
      await _saveAuth(token, profile.username, email: profile.email);
      await _applyProfile(profile);
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    _token = null;
    _username = null;
    _error = null;
    Analytics.instance.trackEvent('auth', 'logout');
    Analytics.instance.setUser(null);
    notifyListeners();
  }

  Future<void> updateInterests(List<String> interests) async {
    final token = _requireToken();
    final profile = await ApiClient().updateInterests(token, interests);
    await _applyProfile(profile);
    Analytics.instance.trackEvent('profile', 'interests_updated');
  }

  Future<void> _applyProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_interestsKey, profile.interests);
    _interests = profile.interests;
    if ((profile.email ?? '').isNotEmpty) {
      await prefs.setString(_emailKey, profile.email!);
      _email = profile.email;
    }
    if ((profile.avatarUrl ?? '').isNotEmpty) {
      await prefs.setString(_avatarUrlKey, profile.avatarUrl!);
      _avatarUrl = profile.avatarUrl;
    }
    await prefs.setStringList(_favoriteIdsKey, profile.favoriteIds);
    _favoriteIds = profile.favoriteIds.toSet();
    notifyListeners();
  }

  Future<void> updateBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bioKey, bio);
    _bio = bio;
    notifyListeners();
  }

  /// Uploads [bytes] (an image picked via image_picker) to the backend,
  /// which stores it under static/avatars/ on the VPS and returns the
  /// resulting URL - replacing the previous local-only, per-device path.
  Future<void> updateAvatar(List<int> bytes, String filename) async {
    final token = _requireToken();
    final profile = await ApiClient().uploadAvatar(token, bytes, filename);
    await _applyProfile(profile);
    Analytics.instance.trackEvent('profile', 'avatar_updated');
  }

  Future<List<Destination>> destinations({String? query}) {
    return ApiClient().getDestinations(query: query);
  }

  Future<List<Destination>> recommendations() async {
    final token = _requireToken();
    return ApiClient().getRecommendations(token);
  }

  Future<List<Destination>> favorites() async {
    final token = _requireToken();
    return ApiClient().getFavorites(token);
  }

  Future<void> toggleFavorite(String destinationId) async {
    final token = _requireToken();
    final alreadyFavorite = _favoriteIds.contains(destinationId);
    final profile = alreadyFavorite
        ? await ApiClient().removeFavorite(token, destinationId)
        : await ApiClient().addFavorite(token, destinationId);
    await _applyProfile(profile);
    Analytics.instance.trackEvent(
      'destination',
      alreadyFavorite ? 'unfavorited' : 'favorited',
      name: destinationId,
    );
  }

  Future<Itinerary> createItinerary(
    String title,
    List<String> destinations, {
    List<ScheduleEntry>? schedule,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = _requireToken();
    final itinerary = await ApiClient().createItinerary(
      token,
      title,
      destinations,
      schedule: schedule,
      startDate: startDate,
      endDate: endDate,
    );
    Analytics.instance.trackEvent(
      'itinerary',
      'created',
      name: destinations.length.toString(),
    );
    return itinerary;
  }

  Future<List<Itinerary>> itineraries() async {
    final token = _requireToken();
    return ApiClient().getItineraries(token);
  }

  Future<String> aiChat(List<ChatMessage> messages) async {
    final token = _requireToken();
    final reply = await ApiClient().aiChat(token, messages);
    Analytics.instance.trackEvent('ai', 'chat_message');
    return reply;
  }

  Future<String> aiExplain(String destinationId) async {
    final token = _requireToken();
    final reply = await ApiClient().aiExplain(token, destinationId);
    Analytics.instance.trackEvent('ai', 'explain_destination', name: destinationId);
    return reply;
  }

  Future<List<Comment>> comments(String destinationId) async {
    final token = _requireToken();
    return ApiClient().getComments(token, destinationId);
  }

  Future<Comment> postComment(String destinationId, String text, {String? parentId}) async {
    final token = _requireToken();
    final comment = await ApiClient().postComment(token, destinationId, text, parentId: parentId);
    Analytics.instance.trackEvent('comment', parentId == null ? 'posted' : 'replied', name: destinationId);
    return comment;
  }

  Future<Comment> voteComment(String commentId, String direction) async {
    final token = _requireToken();
    final comment = await ApiClient().voteComment(token, commentId, direction);
    Analytics.instance.trackEvent('comment', 'voted_$direction');
    return comment;
  }

  Future<void> _saveAuth(
    String token,
    String username, {
    String? email,
    List<String>? interests,
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

    if (interests != null) {
      await prefs.setStringList(_interestsKey, interests);
      _interests = interests;
    }

    if (isNewAccount || _memberSince == null) {
      final now = DateTime.now();
      await prefs.setString(_memberSinceKey, now.toIso8601String());
      _memberSince = now;
    }

    Analytics.instance.setUser(username);
    Analytics.instance.trackEvent(
      'auth',
      isNewAccount ? 'register' : 'login',
    );
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
