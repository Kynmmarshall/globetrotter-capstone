import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/screens/destination_detail_page.dart';
import 'package:trip_io/services/session_controller.dart';

/// Renders AI-generated text that may reference destinations as
/// `[[Name|id]]` (see the system prompt in the backend's ai.py) as tappable
/// links to that destination's detail page, instead of showing the raw
/// internal id. Also strips markdown emphasis markers (`**bold**`,
/// `*italic*`) the model might still slip in despite being told not to - a
/// cheap client-side safety net, since this text is shown as a plain chat
/// bubble or paragraph, not rendered markdown.
///
/// Used by both the AI chat sheet and the destination detail page's "AI
/// explanation" section, since both go through the same system prompt and
/// can contain the same `[[Name|id]]` tags.
class AiFormattedText extends StatelessWidget {
  const AiFormattedText({
    super.key,
    required this.content,
    required this.session,
    required this.style,
  });

  final String content;
  final SessionController session;
  final TextStyle style;

  static final RegExp _linkPattern = RegExp(r'\[\[([^\|\]]+)\|([^\]]+)\]\]');
  static final RegExp _boldPattern = RegExp(r'\*\*([^*]+)\*\*|__([^_]+)__');
  static final RegExp _italicPattern = RegExp(r'\*([^*]+)\*|_([^_\s][^_]*)_');

  static String _stripMarkdown(String text) {
    return text
        .replaceAllMapped(_boldPattern, (m) => m.group(1) ?? m.group(2) ?? '')
        .replaceAllMapped(_italicPattern, (m) => m.group(1) ?? m.group(2) ?? '');
  }

  Future<void> _openDestination(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final destination = await session.destination(id);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DestinationDetailPage(
            destination: destination,
            heroTag: 'destination-${destination.id}',
            session: session,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.aiLinkOpenFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkColor = Theme.of(context).colorScheme.tertiary;
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _linkPattern.allMatches(content)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(text: _stripMarkdown(content.substring(lastEnd, match.start))),
        );
      }
      final name = match.group(1)!.trim();
      final id = match.group(2)!.trim();
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _openDestination(context, id),
            child: Text(
              name,
              style: style.copyWith(
                color: linkColor,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
              ),
            ),
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < content.length) {
      spans.add(TextSpan(text: _stripMarkdown(content.substring(lastEnd))));
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}
