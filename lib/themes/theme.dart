import 'package:flutter/material.dart';

import 'package:trip_io/themes/trip_colors.dart';

class AppTheme {
  static const Color _seed = Color(0xFF0A7E8C);

  /// The app's default look - dark chrome, frosted glass panels. Previously
  /// the only theme, built without an explicit `brightness`, which meant
  /// unstyled Material widgets (a bare `AlertDialog`, `SnackBar`, or bottom
  /// sheet with no color overrides) were actually rendering with Flutter's
  /// *light*-theme defaults the whole time - a white dialog popping up over
  /// an otherwise all-dark screen. Setting `Brightness.dark` here fixes
  /// that mismatch as a side effect, not just enables [lightTheme].
  static ThemeData get theme => _buildTheme(Brightness.dark, TripColors.dark);

  /// For users who want (or whose OS is set to) a light appearance - most
  /// relevant outdoors, where a dark UI is hard to read in direct sun.
  static ThemeData get lightTheme =>
      _buildTheme(Brightness.light, TripColors.light);

  static ThemeData _buildTheme(Brightness brightness, TripColors colors) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: brightness,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      extensions: [colors],
    );
  }
}
