import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/services/session_controller.dart';

/// Heuristic for telling an expired/invalid-token failure apart from other
/// request errors, so screens can offer a "sign in again" action instead of
/// a raw error string.
bool isAuthError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('token') || message.contains('authenticat') || message.contains('401');
}

class SessionExpiredCard extends StatelessWidget {
  const SessionExpiredCard({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.lock_clock, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(
            l10n.sessionExpiredTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.sessionExpiredSubtitle,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => session.logout(),
            icon: const Icon(Icons.login, size: 18),
            label: Text(l10n.signInAgainButton),
          ),
        ],
      ),
    );
  }
}

class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 36),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, color: Colors.white38, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(color: Colors.white60), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
