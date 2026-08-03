import 'package:flutter/material.dart';

/// Shows a destination's rating as five stars, in two modes:
///  - Display (default): renders [average] (half-star precision) plus the
///    vote count - used on cards and anywhere the viewer isn't rating.
///  - Interactive: renders the *viewer's own* [userRating] and lets them
///    tap a star to set it - used on the destination detail screen.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    this.average,
    this.count = 0,
    this.userRating,
    this.interactive = false,
    this.onRate,
    this.size = 16,
    this.hideWhenEmpty = true,
  });

  final double? average;
  final int count;
  final int? userRating;
  final bool interactive;
  final ValueChanged<int>? onRate;
  final double size;

  /// In display mode, collapse to nothing rather than showing "no ratings"
  /// clutter on every card - a destination with zero ratings just shows no
  /// stars at all until someone rates it.
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context) {
    if (!interactive && hideWhenEmpty && count == 0) {
      return const SizedBox.shrink();
    }

    final filledUpTo = interactive
        ? (userRating ?? 0).toDouble()
        : (average ?? 0);
    final starColor = interactive ? Colors.amber : const Color(0xFFFFC670);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++) _buildStar(i, filledUpTo, starColor),
        if (!interactive && count > 0) ...[
          const SizedBox(width: 5),
          Text(
            '${average!.toStringAsFixed(1)} ($count)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: size * 0.72,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (interactive) ...[
          const SizedBox(width: 8),
          Text(
            count > 0
                ? '${average!.toStringAsFixed(1)} ($count)'
                : 'No ratings yet',
            style: TextStyle(color: Colors.white60, fontSize: size * 0.7),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int index, double filledUpTo, Color color) {
    IconData icon;
    if (filledUpTo >= index) {
      icon = Icons.star;
    } else if (filledUpTo >= index - 0.5) {
      icon = Icons.star_half;
    } else {
      icon = Icons.star_border;
    }
    final star = Icon(
      icon,
      size: size,
      color: filledUpTo > 0 ? color : Colors.white38,
    );
    if (!interactive) return star;
    return InkWell(
      onTap: onRate == null ? null : () => onRate!(index),
      borderRadius: BorderRadius.circular(999),
      child: Padding(padding: const EdgeInsets.all(2), child: star),
    );
  }
}
