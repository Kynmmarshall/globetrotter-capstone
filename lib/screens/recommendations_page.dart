import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/destination_detail_page.dart';
import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/add_to_itinerary_button.dart';
import 'package:trip_io/widgets/comment_count_button.dart';
import 'package:trip_io/widgets/directions_button.dart';
import 'package:trip_io/widgets/favorite_toggle_button.dart';
import 'package:trip_io/widgets/feature_pill.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/new_comments_badge.dart';
import 'package:trip_io/widgets/session_expired_card.dart';
import 'package:trip_io/widgets/skeleton_loaders.dart';
import 'package:trip_io/widgets/star_rating.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late Future<List<Destination>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.session.recommendations();
  }

  Widget _buildThumbnail(
    BuildContext context,
    Destination item,
    String heroTag,
  ) {
    final imageUrl = ApiClient.resolveAssetUrl(item.imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 92,
        height: 92,
        child: Hero(
          tag: heroTag,
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
                  errorBuilder: (context, error, stackTrace) =>
                      _fallbackThumb(context),
                )
              : _fallbackThumb(context),
        ),
      ),
    );
  }

  Widget _fallbackThumb(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.star, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Destination item) {
    final l10n = AppLocalizations.of(context)!;
    final heroTag = 'destination-${item.id}';
    return Semantics(
      button: true,
      label: l10n.destinationCardSemanticLabel(item.name),
      child: GestureDetector(
        onTap: () {
          Analytics.instance.trackEvent('destination', 'view', name: item.id);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DestinationDetailPage(
                destination: item,
                heroTag: heroTag,
                session: widget.session,
              ),
            ),
          );
        },
        child: GlassPanel(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(context, item, heroTag),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        NewCommentsBadge(
                          session: widget.session,
                          destination: item,
                        ),
                        const SizedBox(width: 6),
                        DirectionsButton(
                          session: widget.session,
                          destination: item,
                          size: 18,
                        ),
                        const SizedBox(width: 2),
                        AddToItineraryButton(
                          session: widget.session,
                          destinationId: item.id,
                          size: 18,
                        ),
                        const SizedBox(width: 2),
                        FavoriteToggleButton(
                          session: widget.session,
                          destinationId: item.id,
                          size: 18,
                        ),
                      ],
                    ),
                    if (item.hasRatings) ...[
                      const SizedBox(height: 2),
                      StarRating(
                        average: item.ratingAverage,
                        count: item.ratingCount,
                        size: 12.5,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.location ?? item.country,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CommentCountButton(
                          session: widget.session,
                          destination: item,
                        ),
                      ],
                    ),
                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.tags
                            .map((t) => FeaturePill(icon: Icons.sell, label: t))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recommendationsTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.recommendationsSubtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Destination>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DestinationListSkeleton();
              }
              if (snapshot.hasError) {
                if (isAuthError(snapshot.error!)) {
                  return SessionExpiredCard(session: widget.session);
                }
                return ErrorStateCard(
                  message: l10n.recommendationsErrorMessage(
                    snapshot.error.toString(),
                  ),
                );
              }
              final items = snapshot.data ?? <Destination>[];
              if (items.isEmpty) {
                return EmptyStateCard(
                  icon: Icons.explore_off,
                  title: l10n.recommendationsEmptyTitle,
                  subtitle: l10n.recommendationsEmptySubtitle,
                );
              }
              return Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCard(context, item),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
