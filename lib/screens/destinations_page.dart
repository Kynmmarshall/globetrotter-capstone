import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/session_expired_card.dart';

class DestinationsPage extends StatefulWidget {
  const DestinationsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<DestinationsPage> createState() => _DestinationsPageState();
}

class _DestinationsPageState extends State<DestinationsPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Destination>> _future;

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
      _future = widget.session.destinations(query: _searchController.text.trim());
    });
  }

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _glassPanel({required Widget child, EdgeInsets? padding, BorderRadius? borderRadius}) {
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
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(
          color: Colors.white10,
          child: Center(child: Icon(Icons.image_not_supported, color: Colors.white38, size: 32)),
        );
      },
    );
  }

  Widget _buildResultCard(BuildContext context, Destination d) {
    final imageUrl = ApiClient.resolveAssetUrl(d.imageUrl);
    return _glassPanel(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: imageUrl != null
                ? _buildDestinationImage(imageUrl)
                : const ColoredBox(
                    color: Colors.white10,
                    child: Center(child: Icon(Icons.place, color: Colors.white38, size: 32)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 15, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        d.location ?? d.country,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.35),
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
              _sectionTitle(
                context,
                l10n.destinationsTitle,
                subtitle: l10n.destinationsSubtitle,
              ),
              const SizedBox(height: 14),
              _buildSearchBar(l10n),
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
                    return ErrorStateCard(message: l10n.destinationsLoadError(snapshot.error.toString()));
                  }
                  final items = snapshot.data ?? <Destination>[];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(l10n.destinationsEmpty, style: const TextStyle(color: Colors.white70)),
                      ),
                    );
                  }
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 1100 ? 4 : (width >= 820 ? 3 : (width >= 520 ? 2 : 1));
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
                    itemBuilder: (context, index) => _buildResultCard(context, items[index]),
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
