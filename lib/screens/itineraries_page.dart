import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ItinerariesPage> createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  final _titleController = TextEditingController();
  final _destinationsController = TextEditingController();
  late Future<List<Itinerary>> _future;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _future = widget.session.itineraries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationsController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.session.itineraries();
    });
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    final destinations = _destinationsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (title.isEmpty || destinations.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter title and at least one destination id.')),
      );
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      await widget.session.createItinerary(title, destinations);
      _titleController.clear();
      _destinationsController.clear();
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itinerary created.')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
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

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
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
          _glassPanel(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan a new itinerary',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: _fieldDecoration('Itinerary title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _destinationsController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: _fieldDecoration('Destination IDs (comma-separated)', hint: 'd1,d2'),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _creating ? null : _create,
                    child: _creating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create Itinerary'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your itineraries',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Itinerary>>(
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
              final items = snapshot.data ?? <Itinerary>[];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No itineraries yet.', style: TextStyle(color: Colors.white70)),
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
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.tertiary,
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.map, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Destinations: ${item.destinations.join(', ')}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                  ),
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
