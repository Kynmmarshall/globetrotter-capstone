import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/models/yaounde_spot.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/feature_pill.dart';

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

  Widget _buildFeaturedCard(BuildContext context, YaoundeSpot spot) {
    return _glassPanel(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.asset(spot.imageAsset, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
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
                        spot.location,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  spot.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.35),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context, double width) {
    final crossAxisCount = width >= 1100 ? 4 : (width >= 820 ? 3 : (width >= 520 ? 2 : 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          context,
          'Featured in Yaoundé',
          subtitle: 'Must-see landmarks in Cameroon\'s capital, hand-picked for your itinerary.',
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: yaoundeSpots.length,
          itemBuilder: (context, index) => _buildFeaturedCard(context, yaoundeSpots[index]),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search destinations by name or tag',
                hintStyle: TextStyle(color: Colors.white60),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          FilledButton(onPressed: _search, child: const Text('Search')),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Destination d) {
    return _glassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.place, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(d.country, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: d.tags.map((t) => FeaturePill(icon: Icons.sell, label: t)).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeaturedSection(context, constraints.maxWidth),
              const SizedBox(height: 28),
              _sectionTitle(context, 'Search All Destinations'),
              const SizedBox(height: 14),
              _buildSearchBar(),
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
                      ),
                    );
                  }
                  final items = snapshot.data ?? <Destination>[];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No destinations found.', style: TextStyle(color: Colors.white70)),
                      ),
                    );
                  }
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 1000 ? 3 : (width >= 650 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
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
