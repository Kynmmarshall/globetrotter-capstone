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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Itinerary title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destinationsController,
                    decoration: const InputDecoration(
                      labelText: 'Destination IDs (comma-separated)',
                      hintText: 'd1,d2',
                    ),
                  ),
                  const SizedBox(height: 10),
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
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Itinerary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? <Itinerary>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No itineraries yet.'));
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        title: Text(item.title),
                        subtitle: Text('Destinations: ${item.destinations.join(', ')}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
