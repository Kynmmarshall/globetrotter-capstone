import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/comments_section.dart';

/// A small "💬 12" pill for a destination card - shows the total comment
/// count (comments + replies) and opens the comment sheet on tap. Distinct
/// from [NewCommentsBadge], which only appears when there's something
/// unread; this one is always visible so a destination with lots of
/// discussion (or none at all yet) is obvious at a glance from the card.
class CommentCountButton extends StatelessWidget {
  const CommentCountButton({
    super.key,
    required this.session,
    required this.destination,
    this.size = 14,
  });

  final SessionController session;
  final Destination destination;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => showCommentsSheet(
        context,
        session: session,
        destinationId: destination.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: size,
              color: Colors.white70,
              semanticLabel: l10n.commentsButtonLabel,
            ),
            const SizedBox(width: 3),
            Text(
              '${destination.commentCount}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: size - 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
