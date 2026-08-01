import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/map_page.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/comments_section.dart';
import 'package:trip_io/widgets/favorite_toggle_button.dart';
import 'package:trip_io/widgets/star_rating.dart';

class DestinationDetailPage extends StatefulWidget {
  const DestinationDetailPage({
    super.key,
    required this.destination,
    required this.heroTag,
    required this.session,
  });

  final Destination destination;
  final String heroTag;
  final SessionController session;

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  static const double _backgroundBreakpoint = 700;

  late Destination _destination;
  bool _explaining = false;
  String? _explanation;
  String? _explainError;
  bool _rating = false;

  Destination get destination => _destination;
  String get heroTag => widget.heroTag;

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
  }

  Future<void> _rate(int stars) async {
    if (_rating) return;
    setState(() => _rating = true);
    try {
      // Tapping the star that's already the user's current rating clears
      // it instead of re-submitting the same value - lets someone take
      // back a rating without a separate control for it.
      final updated = destination.userRating == stars
          ? await widget.session.clearRating(destination.id)
          : await widget.session.rateDestination(destination.id, stars);
      setState(() {
        _destination = _destination.withRating(
          ratingAverage: updated.ratingAverage,
          ratingCount: updated.ratingCount,
          userRating: updated.userRating,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  Future<void> _askAi() async {
    setState(() {
      _explaining = true;
      _explainError = null;
    });
    try {
      final reply = await widget.session.aiExplain(destination.id);
      setState(() => _explanation = reply);
    } catch (e) {
      setState(() => _explainError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _explaining = false);
    }
  }

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

  Widget _buildAiExplainSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _glassPanel(
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiExplainTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (_explanation == null)
                TextButton.icon(
                  onPressed: _explaining ? null : _askAi,
                  icon: _explaining
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                        )
                      : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                  label: Text(
                    l10n.aiExplainButton,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (_explainError != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.aiExplainError,
              style: TextStyle(color: Colors.red.shade100, fontSize: 12.5),
            ),
          ],
          if (_explanation != null) ...[
            const SizedBox(height: 10),
            Text(
              _explanation!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewOnMapButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MapPage(
              session: widget.session,
              focusDestination: destination,
              showAppBar: true,
            ),
          ),
        ),
        child: _glassPanel(
          borderRadius: BorderRadius.circular(22),
          child: Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.viewOnMapButton,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showCommentsSheet(context, session: widget.session, destinationId: destination.id),
        child: _glassPanel(
          borderRadius: BorderRadius.circular(22),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.commentsButtonLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const Icon(Icons.keyboard_arrow_up, color: Colors.white70),
            ],
          ),
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
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          destination.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 22,
                                          ),
                                        ),
                                      ),
                                      FavoriteToggleButton(
                                        session: widget.session,
                                        destinationId: destination.id,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Opacity(
                                    opacity: _rating ? 0.5 : 1,
                                    child: IgnorePointer(
                                      ignoring: _rating,
                                      child: StarRating(
                                        average: destination.ratingAverage,
                                        count: destination.ratingCount,
                                        userRating: destination.userRating,
                                        interactive: true,
                                        size: 22,
                                        onRate: _rate,
                                      ),
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
                            const SizedBox(height: 18),
                            _buildAiExplainSection(context),
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
                            if (destination.hasCoordinates) ...[
                              const SizedBox(height: 22),
                              _buildViewOnMapButton(context),
                            ],
                            const SizedBox(height: 22),
                            _buildCommentsButton(context),
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
