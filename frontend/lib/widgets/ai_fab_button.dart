import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';

/// The AI chat entry point shown on every dashboard tab - a gentle,
/// continuous pulse (subtle scale + glow) so it stays noticeable without
/// being distracting, since unlike other buttons nothing else on screen
/// points at it.
class AiFabButton extends StatefulWidget {
  const AiFabButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AiFabButton> createState() => _AiFabButtonState();
}

class _AiFabButtonState extends State<AiFabButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [primary, tertiary]),
          ),
          child: Icon(
            Icons.smart_toy,
            color: Colors.white,
            size: 26,
            semanticLabel: l10n.aiChatTitle,
          ),
        ),
      ),
    );

    if (reduceMotion) return button;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Transform.scale(
          scale: 1.0 + (0.07 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25 + (0.3 * t)),
                  blurRadius: 16 + (12 * t),
                  spreadRadius: 1 + (2 * t),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: button,
    );
  }
}
