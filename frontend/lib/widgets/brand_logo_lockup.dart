import 'dart:ui';

import 'package:flutter/material.dart';

/// The trip_io wordmark + icon, frosted-pill style - shared between the
/// auth screen and the app's initial loading gate, since the background
/// photos both use are logo-free and need this composited on top.
class BrandLogoLockup extends StatelessWidget {
  const BrandLogoLockup({
    super.key,
    this.iconSize = 40,
    this.onTap,
    this.semanticLabel,
  });

  final double iconSize;

  /// Optional - when set, the whole pill becomes tappable (e.g. the auth
  /// screen uses this to open the marketing website). Other call sites
  /// (splash screen, onboarding) simply omit it and stay non-interactive.
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0D2A4A);
    const brandBlue = Color(0xFF1E88E5);
    const shadows = [
      Shadow(blurRadius: 10, color: Colors.white70, offset: Offset(0, 1)),
    ];
    final pill = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: iconSize * 0.3,
              vertical: iconSize * 0.18,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', height: iconSize),
                const SizedBox(width: 10),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: iconSize * 0.6,
                      fontWeight: FontWeight.w800,
                      shadows: shadows,
                    ),
                    children: const [
                      TextSpan(
                        text: 'trip',
                        style: TextStyle(color: navy),
                      ),
                      TextSpan(
                        text: '_io',
                        style: TextStyle(color: brandBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final tapCallback = onTap;
    if (tapCallback == null) return pill;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: tapCallback,
          child: pill,
        ),
      ),
    );
  }
}
