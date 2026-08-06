import 'package:flutter/material.dart';

/// A compact "$" / "$$" / "$$$" affordability badge - shown on destination
/// cards and the detail screen so someone browsing gets a rough price
/// sense without opening the full "Good to know" section. Purely
/// decorative color-coding: budget reads as approachable green, upscale as
/// a richer amber, mid-range in between.
class PriceTierTag extends StatelessWidget {
  const PriceTierTag({super.key, required this.priceTier, this.large = false});

  final String priceTier;

  /// A bigger, more prominent rendering for the detail screen's header,
  /// versus the compact default sized for a card.
  final bool large;

  Color get _color {
    switch (priceTier) {
      case r'$':
        return const Color(0xFF2ECC71);
      case r'$$$':
        return const Color(0xFFF2A93B);
      default:
        return const Color(0xFF5DADE2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7,
          vertical: large ? 5 : 3,
        ),
        child: Text(
          priceTier,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: large ? 13 : 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
