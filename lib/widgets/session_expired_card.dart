import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/services/session_controller.dart';

/// Heuristic for telling an expired/invalid-token failure apart from other
/// request errors, so screens can offer a "sign in again" action instead of
/// a raw error string.
bool isAuthError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('token') ||
      message.contains('authenticat') ||
      message.contains('401');
}

/// Maps common failure shapes (no connection, timed out, server error) to
/// translated, human copy instead of showing raw exception text like
/// "ClientException: Failed host lookup..." - falls back to the exception's
/// own message (with the "Exception: " prefix stripped, for consistency
/// with how the rest of the app already displays ad-hoc errors) when it
/// doesn't recognize the shape.
String friendlyError(Object error, AppLocalizations l10n) {
  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection failed')) {
    return l10n.errorNoConnection;
  }
  if (lower.contains('timeoutexception') || lower.contains('timed out')) {
    return l10n.errorTimedOut;
  }
  if (lower.contains('500') || lower.contains('internal server error')) {
    return l10n.errorServerProblem;
  }
  return raw.replaceFirst('Exception: ', '');
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
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
  const ErrorStateCard({super.key, required this.message, this.onRetry});

  final String message;

  /// Optional - when set, shows a "Try again" button that re-triggers
  /// whatever Future the caller loaded from. Omit for spots where there's
  /// genuinely nothing to retry.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (retry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: retry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context)!.errorTryAgainButton),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
