import 'package:flutter/material.dart';

/// The app's glass-morphism color language, centralized as a
/// [ThemeExtension] instead of the literal `Colors.white.withValues(alpha:
/// …)` values screens used to hardcode independently, one copy per file.
/// Holds the highest-leverage, most-repeated tokens - the ones [GlassPanel]
/// and the dark/light theme split actually need - not an attempt to route
/// every single color reference in the app through this in one pass.
@immutable
class TripColors extends ThemeExtension<TripColors> {
  const TripColors({
    required this.glassFill,
    required this.glassFlatFill,
    required this.glassSolidFill,
    required this.glassBorder,
    required this.glassBorderSolid,
    required this.scrim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.accentSelected,
    required this.accentLink,
    required this.destructive,
    required this.myLocation,
  });

  /// Fill for [GlassPanelStyle.blurred] panels - a photo/background image
  /// shows through the blur behind it.
  final Color glassFill;

  /// Fill for [GlassPanelStyle.flat] panels - already sitting on an opaque
  /// surface (e.g. inside a bottom sheet), so no blur needed.
  final Color glassFlatFill;

  /// Fill for [GlassPanelStyle.solid] panels - sitting on top of a native
  /// platform view (TripMap's MapLibre backend), where BackdropFilter can't
  /// read what's behind it at all.
  final Color glassSolidFill;

  final Color glassBorder;
  final Color glassBorderSolid;

  /// The dark overlay behind full-bleed background photos on standalone
  /// routes (auth, submit destination, itinerary detail, ...).
  final Color scrim;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;

  /// Selected/active map markers and matching UI accents.
  final Color accentSelected;

  /// Route lines, links, and the brand wordmark's second half.
  final Color accentLink;

  /// Destructive-action buttons (delete, logout confirmation).
  final Color destructive;

  /// The "you are here" node/arrow on the map - shared between the
  /// MapLibre and flutter_map backends so it looks identical either way.
  final Color myLocation;

  static final TripColors dark = TripColors(
    glassFill: Colors.white.withValues(alpha: 0.12),
    glassFlatFill: Colors.white.withValues(alpha: 0.1),
    glassSolidFill: const Color(0xFF0B1A24).withValues(alpha: 0.88),
    glassBorder: Colors.white.withValues(alpha: 0.2),
    glassBorderSolid: Colors.white.withValues(alpha: 0.18),
    scrim: Colors.black.withValues(alpha: 0.58),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textMuted: Colors.white54,
    textFaint: Colors.white38,
    accentSelected: const Color(0xFFF2A93B),
    accentLink: const Color(0xFF1E88E5),
    destructive: Colors.red.shade600,
    myLocation: const Color(0xFF2ECC71),
  );

  /// Not a naive inversion - glass panels stay dark-tinted even in light
  /// mode (a white-on-white blurred panel over a bright photo would have
  /// no visible edge at all), so only the *content* - text, panel borders,
  /// the background scrim - actually flips to work on a light ground. The
  /// map/accent colors stay put either way, since they're not
  /// brightness-dependent (a route line or a "you are here" marker needs
  /// to read the same regardless of theme).
  static final TripColors light = TripColors(
    glassFill: const Color(0xFF0B1A24).withValues(alpha: 0.55),
    glassFlatFill: const Color(0xFF0B1A24).withValues(alpha: 0.06),
    glassSolidFill: const Color(0xFF0B1A24).withValues(alpha: 0.88),
    glassBorder: const Color(0xFF0B1A24).withValues(alpha: 0.14),
    glassBorderSolid: Colors.white.withValues(alpha: 0.18),
    scrim: Colors.black.withValues(alpha: 0.32),
    textPrimary: const Color(0xFF10171C),
    textSecondary: const Color(0xFF3D4C52),
    textMuted: const Color(0xFF63737A),
    textFaint: const Color(0xFF8B9AA0),
    accentSelected: const Color(0xFFC97A1F),
    accentLink: const Color(0xFF1565C0),
    destructive: Colors.red.shade700,
    myLocation: const Color(0xFF1E8449),
  );

  @override
  TripColors copyWith({
    Color? glassFill,
    Color? glassFlatFill,
    Color? glassSolidFill,
    Color? glassBorder,
    Color? glassBorderSolid,
    Color? scrim,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? accentSelected,
    Color? accentLink,
    Color? destructive,
    Color? myLocation,
  }) {
    return TripColors(
      glassFill: glassFill ?? this.glassFill,
      glassFlatFill: glassFlatFill ?? this.glassFlatFill,
      glassSolidFill: glassSolidFill ?? this.glassSolidFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBorderSolid: glassBorderSolid ?? this.glassBorderSolid,
      scrim: scrim ?? this.scrim,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      accentSelected: accentSelected ?? this.accentSelected,
      accentLink: accentLink ?? this.accentLink,
      destructive: destructive ?? this.destructive,
      myLocation: myLocation ?? this.myLocation,
    );
  }

  @override
  TripColors lerp(ThemeExtension<TripColors>? other, double t) {
    if (other is! TripColors) return this;
    return TripColors(
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFlatFill: Color.lerp(glassFlatFill, other.glassFlatFill, t)!,
      glassSolidFill: Color.lerp(glassSolidFill, other.glassSolidFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBorderSolid: Color.lerp(
        glassBorderSolid,
        other.glassBorderSolid,
        t,
      )!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accentSelected: Color.lerp(accentSelected, other.accentSelected, t)!,
      accentLink: Color.lerp(accentLink, other.accentLink, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      myLocation: Color.lerp(myLocation, other.myLocation, t)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<TripColors>()!` - every
/// [ThemeData] this app builds registers one, so the bang is safe.
extension TripColorsContext on BuildContext {
  TripColors get tripColors => Theme.of(this).extension<TripColors>()!;
}
