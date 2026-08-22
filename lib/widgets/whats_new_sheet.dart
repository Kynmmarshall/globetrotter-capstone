import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';

/// One entry per notable release - keep this hand-curated and short (a
/// handful of bullets, not a full commit log). Shown once per version bump
/// via [showWhatsNewSheet], driven by [SessionController.lastSeenVersion]/
/// [SessionController.setLastSeenVersion] (see dashboard_screen.dart).
class WhatsNewEntry {
  const WhatsNewEntry({required this.version, required this.bullets});

  final String version;
  final List<String> bullets;
}

/// Update this alongside pubspec.yaml's version bumps - a version with no
/// entry here just gets silently recorded as seen, no sheet shown.
const List<WhatsNewEntry> whatsNewEntries = [
  WhatsNewEntry(
    version: '0.1.0',
    bullets: [
      'Talk to Tia by voice - record a question and hear the answer read back.',
      'Itinerary creation is now its own dedicated screen, with a clearer flow.',
      'A more polished loading screen and smoother tab transitions.',
    ],
  ),
];

Future<void> showWhatsNewSheet(BuildContext context, WhatsNewEntry entry) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF13253A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.whatsNewTitle(entry.version),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final bullet in entry.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.whatsNewDismiss),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
