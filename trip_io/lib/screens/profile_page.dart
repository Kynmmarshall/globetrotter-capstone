import 'package:flutter/material.dart';
import 'package:trip_io/services/session_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as: ${session.username ?? 'unknown'}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => session.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
