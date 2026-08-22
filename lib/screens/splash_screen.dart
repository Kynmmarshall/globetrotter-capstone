import 'dart:math' as math;

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
  // A slow Ken Burns zoom/pan on the background photo itself - previously
  // completely static, which read as flat next to the animated logo.
  late final AnimationController _bgZoom;
  // Drifting glow particles over the photo, in the same brand palette and
  // "anti-gravity" spirit as the marketing website's star field
  // (trip_io_backend/website/script.js's initStarField()).
  late final AnimationController _particles;
  late final List<_Particle> _particleSeeds;

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
    _bgZoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat(reverse: true);
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();
    _particleSeeds = _Particle.generate(26, math.Random(7));

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
    _bgZoom.dispose();
    _particles.dispose();
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

  Widget _background(bool isCompact) {
    final image = Image.asset(
      isCompact ? 'assets/backgrounds/mobile.png' : 'assets/backgrounds/pc.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
    return AnimatedBuilder(
      animation: _bgZoom,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bgZoom.value);
        return Transform.scale(
          scale: 1.0 + (0.09 * t),
          alignment: Alignment.lerp(
            const Alignment(-0.06, -1.0),
            const Alignment(0.06, -0.85),
            t,
          )!,
          child: child,
        );
      },
      child: image,
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
              reduceMotion
                  ? Image.asset(
                      isCompact
                          ? 'assets/backgrounds/mobile.png'
                          : 'assets/backgrounds/pc.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : ClipRect(child: _background(isCompact)),
              DecoratedBox(
                decoration: BoxDecoration(color: context.tripColors.scrim),
              ),
              // A splash-only extra vignette (on top of the shared scrim
              // above) - the background photo is bright/busy enough that
              // the particle layer needs more contrast to actually read as
              // "captivating" rather than blending into the sky.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [Colors.transparent, Color(0x59000000)],
                  ),
                ),
              ),
              if (!reduceMotion)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _particles,
                    builder: (context, child) => CustomPaint(
                      painter: _ParticlesPainter(
                        particles: _particleSeeds,
                        progress: _particles.value,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!reduceMotion) _glow(colorScheme),
                        logo,
                      ],
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

class _Particle {
  const _Particle({
    required this.dx,
    required this.startY,
    required this.size,
    required this.color,
    required this.speed,
    required this.phase,
  });

  /// Horizontal position as a fraction of width (0..1) - fixed, particles
  /// only drift vertically.
  final double dx;
  final double startY;
  final double size;
  final Color color;
  final double speed;
  final double phase;

  static const _palette = [
    Colors.white,
    Color(0xFF14B8C4), // brand-teal-light
    Color(0xFF1E88E5), // brand-blue
    Color(0xFFFFC670), // brand-amber-light
  ];

  static List<_Particle> generate(int count, math.Random random) {
    return List.generate(count, (_) {
      return _Particle(
        dx: random.nextDouble(),
        startY: random.nextDouble(),
        size: 2.2 + random.nextDouble() * 3.0,
        color: _palette[random.nextInt(_palette.length)],
        speed: 0.4 + random.nextDouble() * 0.8,
        phase: random.nextDouble() * math.pi * 2,
      );
    });
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Drifts upward continuously and wraps back in at the bottom.
      final y = (1 - ((p.startY + progress * p.speed) % 1.0)) * size.height;
      final x = p.dx * size.width;
      final twinkle =
          0.55 + 0.45 * (0.5 + 0.5 * math.sin(progress * 2 * math.pi * 2 + p.phase));
      final offset = Offset(x, y);

      // A soft outer glow plus a crisp, brighter core - a single blurred
      // circle alone washes out against a bright, busy photo.
      canvas.drawCircle(
        offset,
        p.size * 2.2,
        Paint()
          ..color = p.color.withValues(alpha: twinkle * 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.4),
      );
      canvas.drawCircle(
        offset,
        p.size * 0.55,
        Paint()..color = p.color.withValues(alpha: (twinkle * 1.1).clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
