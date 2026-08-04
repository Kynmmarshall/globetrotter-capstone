import 'package:flutter/material.dart';

/// Wraps [child] in a gentle opacity pulse - the "shimmer" cue for loading
/// placeholders. Respects the platform's reduce-motion setting by simply
/// not animating at all rather than ignoring it.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// A single shimmering rounded-rect placeholder - the base unit every
/// skeleton layout below is built from.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// One placeholder card, shaped like [DestinationsPage]'s grid result card
/// (`_buildResultCard`) - a 4:3 image block over two lines of text.
class DestinationCardSkeleton extends StatelessWidget {
  const DestinationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 4 / 3, child: SkeletonBox(borderRadius: 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: double.infinity, height: 15),
                const SizedBox(height: 8),
                SkeletonBox(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full grid of [DestinationCardSkeleton]s, matching the real grid's
/// responsive column count and aspect ratio so the transition from
/// skeleton to real content doesn't visibly jump.
class DestinationGridSkeleton extends StatelessWidget {
  const DestinationGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 4
            : (width >= 820 ? 3 : (width >= 520 ? 2 : 1));
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.63,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => const DestinationCardSkeleton(),
        );
      },
    );
  }
}

/// One placeholder row, shaped like [RecommendationsPage]/[FavoritesPage]'s
/// list card - a square thumbnail beside a few lines of text.
class DestinationRowSkeleton extends StatelessWidget {
  const DestinationRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 92, height: 92, borderRadius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: double.infinity, height: 15),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 12),
                  const SizedBox(height: 10),
                  const SkeletonBox(width: double.infinity, height: 11),
                  const SizedBox(height: 6),
                  SkeletonBox(width: 200, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A column of [DestinationRowSkeleton]s, for the list-style pages.
class DestinationListSkeleton extends StatelessWidget {
  const DestinationListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          const DestinationRowSkeleton(),
        ],
      ],
    );
  }
}
