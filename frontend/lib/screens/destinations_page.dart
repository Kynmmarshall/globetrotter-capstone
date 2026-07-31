import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/interest_tags.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/destination_detail_page.dart';
import 'package:trip_io/screens/submit_destination_page.dart';
import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/favorite_toggle_button.dart';
import 'package:trip_io/widgets/session_expired_card.dart';
import 'package:trip_io/widgets/star_rating.dart';

class DestinationsPage extends StatefulWidget {
  const DestinationsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<DestinationsPage> createState() => _DestinationsPageState();
}

class _DestinationsPageState extends State<DestinationsPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Destination>> _future;
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _future = widget.session.destinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _future = widget.session.destinations(
        query: _searchController.text.trim(),
      );
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  List<Destination> _applyFilters(List<Destination> items) {
    if (_selectedTags.isEmpty) return items;
    return items
        .where((d) => d.tags.any(_selectedTags.contains))
        .toList();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _sectionTitle(BuildContext context, String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
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

  Widget _buildDestinationImage(String url) {
    return Image.network(
      url,
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
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(BuildContext context, Destination d) {
    final imageUrl = ApiClient.resolveAssetUrl(d.imageUrl);
    final heroTag = 'destination-${d.id}';
    return GestureDetector(
      onTap: () {
        Analytics.instance.trackEvent('destination', 'view', name: d.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailPage(
              destination: d,
              heroTag: heroTag,
              session: widget.session,
            ),
          ),
        );
      },
      child: _glassPanel(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Hero(
                    tag: heroTag,
                    child: imageUrl != null
                        ? _buildDestinationImage(imageUrl)
                        : const ColoredBox(
                            color: Colors.white10,
                            child: Center(
                              child: Icon(
                                Icons.place,
                                color: Colors.white38,
                                size: 32,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: FavoriteToggleButton(session: widget.session, destinationId: d.id),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (d.hasRatings) ...[
                    const SizedBox(height: 4),
                    StarRating(average: d.ratingAverage, count: d.ratingCount, size: 13),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d.location ?? d.country,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if ((d.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      d.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (d.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: d.tags.map((t) => _buildTagChip(t)).toList(),
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

  Widget _buildSearchBar(AppLocalizations l10n) {
    return _glassPanel(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.destinationsSearchHint,
                hintStyle: const TextStyle(color: Colors.white60),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          FilledButton(onPressed: _search, child: Text(l10n.searchButton)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    return _glassPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.white.withValues(alpha: 0.85), size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.destinationsFilterLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (_selectedTags.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedTags.clear()),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.destinationsFilterClear,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interestTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(
                  _capitalize(tag),
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1A2530),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                avatar: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
                backgroundColor: Colors.white.withValues(alpha: 0.88),
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.85),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                onSelected: (_) => _toggleTag(tag),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _sectionTitle(
                      context,
                      l10n.destinationsTitle,
                      subtitle: l10n.destinationsSubtitle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubmitDestinationPage(session: widget.session),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    icon: const Icon(Icons.add_location_alt, size: 18),
                    label: Text(l10n.suggestDestinationButton),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSearchBar(l10n),
              const SizedBox(height: 12),
              _buildFilterBar(l10n),
              const SizedBox(height: 16),
              FutureBuilder<List<Destination>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return ErrorStateCard(
                      message: l10n.destinationsLoadError(
                        snapshot.error.toString(),
                      ),
                    );
                  }
                  final allItems = snapshot.data ?? <Destination>[];
                  if (allItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          l10n.destinationsEmpty,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }
                  final items = _applyFilters(allItems);
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          l10n.destinationsFilterEmpty,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }
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
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildResultCard(context, items[index]),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
