import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seed = Color(0xFF0A7E8C);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seed,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
