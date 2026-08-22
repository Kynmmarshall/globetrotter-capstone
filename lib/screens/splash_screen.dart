import 'package:flutter/material.dart';

import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/widgets/brand_logo_lockup.dart';

/// Shown while [SessionController] resolves whether a saved session is
/// still valid - previously a bare spinner on the default (unthemed) white
/// Scaffold background, which meant the very first frame of the app didn't
/// match the brand at all. Reuses the same responsive background photo and
/// logo lockup as [AuthScreen] so the transition into it (if there's no
/// valid session) is seamless rather than a jump cut.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const double _backgroundBreakpoint = 700;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Plays once: the logo pops in, the spinner fades in slightly after -
  // staggered rather than everything appearing at once.
  late final AnimationController _entrance;
  // Loops for as long as the splash is on screen: a soft glow behind the
  // logo breathing in opacity/scale, echoing the marketing website's
  // hero-logo-halo treatment (trip_io_backend/website/css/style.css) so the
  // app's own loading moment feels like the same brand.
  late final AnimationController _ambient;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _spinnerFade;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _logoScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _spinnerFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Widget _glow(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final t = _ambient.value;
        return Opacity(
          opacity: 0.35 + (0.3 * t),
          child: Transform.scale(
            scale: 0.92 + (0.16 * t),
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.55),
                    colorScheme.tertiary.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same signal Flutter exposes for the OS-level "reduce motion" setting -
    // ai_fab_button.dart's pulsing FAB checks this the same way.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final colorScheme = Theme.of(context).colorScheme;

    final logo = reduceMotion
        ? const BrandLogoLockup(iconSize: 46)
        : ScaleTransition(
            scale: _logoScale,
            child: FadeTransition(
              opacity: _logoFade,
              child: const BrandLogoLockup(iconSize: 46),
            ),
          );

    const spinner = SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxWidth < SplashScreen._backgroundBreakpoint;
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
                decoration: BoxDecoration(color: context.tripColors.scrim),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!reduceMotion) _glow(colorScheme),
                          logo,
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    reduceMotion
                        ? spinner
                        : FadeTransition(
                            opacity: _spinnerFade,
                            child: spinner,
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
