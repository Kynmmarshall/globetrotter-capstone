import 'package:flutter/material.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
            return const Center(child: Text('No recommendations yet.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.place),
                title: Text(item.name),
                subtitle: Text('${item.country}  •  ${item.tags.join(', ')}'),
              );
            },
          );
        },
      ),
    );
  }
}
