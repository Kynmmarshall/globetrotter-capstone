import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal client for Matomo's HTTP Tracking API
/// (https://developer.matomo.org/api-reference/tracking-api).
///
/// Deliberately not the matomo_tracker package: this is a handful of GET
/// requests, and writing it directly means identical behaviour on every
/// Flutter target (mobile/Windows/web) with no platform channels, and no
/// dependency on a third-party package's maintenance state.
class Analytics {
  Analytics._();

  static final Analytics instance = Analytics._();

  static const _trackUrl = 'https://trip-io-analytics.duckdns.org/matomo.php';
  static const _siteId = '1';
  static const _visitorIdKey = 'gt_matomo_visitor_id';

  final http.Client _client = http.Client();
  String? _visitorId;
  String? _username;

  /// Call after login/register so events are attributable to a user, and
  /// with null on logout.
  void setUser(String? username) {
    _username = username;
  }

  Future<void> trackScreen(String screenName) {
    return _send({
      'action_name': screenName,
      'url': 'app://trip_io/${_platform()}/$screenName',
    });
  }

  Future<void> trackEvent(String category, String action, {String? name}) {
    return _send({
      'e_c': category,
      'e_a': action,
      'e_n': ?name,
      'action_name': '$category / $action',
      'url': 'app://trip_io/${_platform()}/event/$category/$action',
    });
  }

  Future<void> _send(Map<String, String> params) async {
    try {
      final visitorId = await _ensureVisitorId();
      final query = {
        'idsite': _siteId,
        'rec': '1',
        'apiv': '1',
        '_id': visitorId,
        'rand': DateTime.now().millisecondsSinceEpoch.toString(),
        'send_image': '0',
        'uid': ?_username,
        ...params,
      };
      final uri = Uri.parse(_trackUrl).replace(queryParameters: query);
      await _client.get(uri).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Analytics must never break the app - network errors, timeouts, an
      // unreachable tracker, all silently swallowed.
    }
  }

  Future<String> _ensureVisitorId() async {
    final cached = _visitorId;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_visitorIdKey);
    if (id == null) {
      id = _generateVisitorId();
      await prefs.setString(_visitorIdKey, id);
    }
    _visitorId = id;
    return id;
  }

  // Matomo requires exactly 16 hex characters for a custom visitor id.
  String _generateVisitorId() {
    final rand = Random.secure();
    return List.generate(
      16,
      (_) => rand.nextInt(16).toRadixString(16),
    ).join();
  }

  String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
