import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';

/// A small "New" pill for a destination card, shown when [destination] has
/// more comments/replies than this device has last seen - same locally
/// tracked count the comments button badge on the detail page uses (see
/// SessionController.lastSeenCommentCount), so viewing the comments there
/// clears this too.
class NewCommentsBadge extends StatelessWidget {
  const NewCommentsBadge({super.key, required this.session, required this.destination});

  final SessionController session;
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    if (destination.commentCount <= 0) return const SizedBox.shrink();
    return FutureBuilder<int>(
      future: session.lastSeenCommentCount(destination.id),
      builder: (context, snapshot) {
        final lastSeen = snapshot.data;
        if (lastSeen == null || destination.commentCount <= lastSeen) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context)!;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.forum, size: 10, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  l10n.commentsNewBadge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
