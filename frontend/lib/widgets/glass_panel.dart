import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:trip_io/themes/trip_colors.dart';

/// Which background a [GlassPanel] sits over - this changes what "glass"
/// effect actually works, so it's a real functional choice, not a purely
/// stylistic one.
enum GlassPanelStyle {
  /// The usual frosted-glass look: white-tinted fill + backdrop blur, for
  /// panels sitting directly over a photo/background image.
  blurred,

  /// Same tint and border as [blurred] but no blur - for panels sitting on
  /// top of a native platform view (e.g. TripMap's MapLibre backend on
  /// Android/Web). BackdropFilter can't sample a platform view's own
  /// compositing layer, so the blur silently no-ops there, leaving text
  /// with no readable background at all. A solid, mostly-opaque dark fill
  /// works the same on every backend instead.
  solid,

  /// A plain low-alpha card with no blur and no extra clip - for panels
  /// that already sit inside an opaque surface (e.g. a bottom sheet with
  /// its own solid background), where blurring an already-flat color would
  /// be pure wasted compositing work.
  flat,
}

/// The app's shared frosted/glass card treatment - one definition instead
/// of the near-identical `_glassPanel()` helper every major screen used to
/// hand-roll on its own (destinations, favorites, recommendations, map,
/// itineraries, profile, submit-destination, comments, AI chat...). A
/// future tweak to blur radius, tint, or border now happens once, here.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.style = GlassPanelStyle.blurred,
  });

  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final GlassPanelStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = context.tripColors;
    final radius = borderRadius ?? BorderRadius.circular(18);
    final fill = switch (style) {
      GlassPanelStyle.solid => colors.glassSolidFill,
      GlassPanelStyle.flat => colors.glassFlatFill,
      GlassPanelStyle.blurred => colors.glassFill,
    };
    final borderColor = style == GlassPanelStyle.solid
        ? colors.glassBorderSolid
        : colors.glassBorder;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    switch (style) {
      case GlassPanelStyle.flat:
        return content;
      case GlassPanelStyle.solid:
        return ClipRRect(borderRadius: radius, child: content);
      case GlassPanelStyle.blurred:
        return ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: content,
          ),
        );
    }
  }
}
