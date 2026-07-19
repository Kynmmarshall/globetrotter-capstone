import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/feature_pill.dart';

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

  Widget _glassPanel({required Widget child, EdgeInsets? padding, BorderRadius? borderRadius}) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Picked for you',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A quick shortlist of Yaoundé spots worth adding to your itinerary.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
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
                    child: Text('No recommendations yet.', style: TextStyle(color: Colors.white70)),
                  ),
                );
              }
              return Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _glassPanel(
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.tertiary,
                                ],
                              ),
                            ),
                            child: const Icon(Icons.star, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(item.country, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                                if (item.tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: item.tags.map((t) => FeaturePill(icon: Icons.sell, label: t)).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
