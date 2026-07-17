import 'package:flutter/material.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(labelText: 'Search destinations by name or tag'),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _search, child: const Text('Search')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Destination>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? <Destination>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No destinations found.'));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1000 ? 3 : (width >= 650 ? 2 : 1);
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final d = items[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(d.country),
                                const Spacer(),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: d.tags.map((t) => Chip(label: Text(t))).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
