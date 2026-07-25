import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/api_client.dart';

class DestinationDetailPage extends StatelessWidget {
  const DestinationDetailPage({
    super.key,
    required this.destination,
    required this.heroTag,
  });

  final Destination destination;
  final String heroTag;

  static const double _backgroundBreakpoint = 700;

  Widget _glassPanel({
    required Widget child,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCard(BuildContext context, NearbyPlace place) {
    final icon = place.isHotel ? Icons.hotel : Icons.restaurant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _glassPanel(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  if ((place.location ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 13, color: Colors.white60),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.location!,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((place.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      place.description!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, height: 1.3),
                    ),
                  ],
                  if (place.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: place.tags.map(_buildTagChip).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, String? imageUrl) {
    return Hero(
      tag: heroTag,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const ColoredBox(
                    color: Colors.white10,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: Colors.white10,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white38,
                        size: 48,
                      ),
                    ),
                  );
                },
              )
            : const ColoredBox(
                color: Colors.white10,
                child: Center(
                  child: Icon(Icons.place, color: Colors.white38, size: 48),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiClient.resolveAssetUrl(destination.imageUrl);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompactBackground =
              constraints.maxWidth < _backgroundBreakpoint;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isCompactBackground
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
              SafeArea(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  _buildHeroImage(context, imageUrl),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.35],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _glassPanel(
                              borderRadius: BorderRadius.circular(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    destination.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 18,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          destination.location ??
                                              destination.country,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (destination.tags.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: destination.tags
                                          .map(_buildTagChip)
                                          .toList(),
                                    ),
                                  ],
                                  if ((destination.description ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 18),
                                    const Divider(
                                      color: Colors.white24,
                                      height: 1,
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      destination.description!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (destination.openingHours != null ||
                                destination.entryFee != null ||
                                destination.tips != null) ...[
                              const SizedBox(height: 22),
                              Text(
                                AppLocalizations.of(context)!.practicalInfoTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _glassPanel(
                                borderRadius: BorderRadius.circular(20),
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (destination.openingHours != null)
                                      _buildInfoRow(
                                        Icons.schedule,
                                        AppLocalizations.of(context)!.openingHoursLabel,
                                        destination.openingHours!,
                                      ),
                                    if (destination.entryFee != null)
                                      _buildInfoRow(
                                        Icons.confirmation_number_outlined,
                                        AppLocalizations.of(context)!.entryFeeLabel,
                                        destination.entryFee!,
                                      ),
                                    if (destination.tips != null)
                                      _buildInfoRow(
                                        Icons.lightbulb_outline,
                                        AppLocalizations.of(context)!.tipsLabel,
                                        destination.tips!,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            if (destination.nearby.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              Text(
                                AppLocalizations.of(context)!.nearbyTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.nearbySubtitle,
                                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                              const SizedBox(height: 12),
                              ...destination.nearby.map((place) => _buildNearbyCard(context, place)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _glassPanel(
                      borderRadius: BorderRadius.circular(999),
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
