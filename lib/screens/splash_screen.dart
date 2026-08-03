import 'package:flutter/material.dart';

import 'package:trip_io/widgets/brand_logo_lockup.dart';

/// Shown while [SessionController] resolves whether a saved session is
/// still valid - previously a bare spinner on the default (unthemed) white
/// Scaffold background, which meant the very first frame of the app didn't
/// match the brand at all. Reuses the same responsive background photo and
/// logo lockup as [AuthScreen] so the transition into it (if there's no
/// valid session) is seamless rather than a jump cut.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const double _backgroundBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _backgroundBreakpoint;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isCompact
                    ? 'assets/backgrounds/mobile.png'
                    : 'assets/backgrounds/pc.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                ),
              ),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandLogoLockup(iconSize: 46),
                    SizedBox(height: 28),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
