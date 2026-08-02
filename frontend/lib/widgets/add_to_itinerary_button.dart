import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/itinerary_scheduler.dart';
import 'package:trip_io/services/session_controller.dart';

/// A tappable "add to itinerary" icon, meant to sit on top of a destination
/// card or in a detail page header - same slot pattern as
/// [FavoriteToggleButton]. Tapping it opens a sheet listing the user's
/// itineraries (plus a "create new" option); picking one appends this
/// destination to it if it isn't already there.
class AddToItineraryButton extends StatefulWidget {
  const AddToItineraryButton({
    super.key,
    required this.session,
    required this.destinationId,
    this.size = 20,
  });

  final SessionController session;
  final String destinationId;
  final double size;

  @override
  State<AddToItineraryButton> createState() => _AddToItineraryButtonState();
}

class _AddToItineraryButtonState extends State<AddToItineraryButton> {
  bool _busy = false;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    List<Itinerary> itineraries;
    try {
      itineraries = await widget.session.itineraries();
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (mounted) setState(() => _busy = false);
    if (!mounted) return;

    final choice = await showModalBottomSheet<_ItineraryChoice>(
      context: context,
      backgroundColor: const Color(0xFF13253A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ItineraryPickerSheet(
        itineraries: itineraries,
        destinationId: widget.destinationId,
      ),
    );
    if (choice == null || !mounted) return;

    if (choice.createNew) {
      await _createAndAdd();
    } else {
      await _addToExisting(choice.itinerary!);
    }
  }

  Future<void> _addToExisting(Itinerary itinerary) async {
    final l10n = AppLocalizations.of(context)!;
    // Belt-and-suspenders: the sheet already disables itineraries that have
    // this destination, but re-check here too in case its list was stale by
    // the time the user tapped.
    if (itinerary.destinations.contains(widget.destinationId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToItineraryAlready(itinerary.title))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final destinationIds = [...itinerary.destinations, widget.destinationId];
      // Rebuild the timed plan so the new stop actually shows up on the
      // itinerary detail screen's timeline instead of just sitting in
      // `destinations` with no time slot - same pacing defaults the
      // itineraries page uses for a fresh plan (9am start, 4h/day).
      final tripStart = itinerary.startDate ?? DateTime.now();
      final tripEnd = itinerary.endDate ?? tripStart;
      final dayCount = tripEnd.difference(tripStart).inDays + 1;
      final result = generateMultiDaySchedule(
        destinationIds: destinationIds,
        tripStart: tripStart,
        dayCount: dayCount,
        startHour: 9,
        startMinute: 0,
        dailyAvailable: const Duration(hours: 4),
      );
      await widget.session.updateItinerary(
        itinerary.id,
        destinations: destinationIds,
        schedule: result.entries,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToItineraryAdded(itinerary.title))),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createAndAdd() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addToItineraryNewDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.itineraryTitleLabel,
            hintText: l10n.itineraryTitleHint,
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final itinerary = await widget.session.createItinerary(title, [
        widget.destinationId,
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToItineraryAdded(itinerary.title))),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: _busy
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                Icons.playlist_add,
                color: Colors.white,
                size: widget.size,
                semanticLabel: l10n.addToItineraryTooltip,
              ),
      ),
    );
  }
}

class _ItineraryChoice {
  const _ItineraryChoice.existing(this.itinerary) : createNew = false;
  const _ItineraryChoice.createNew() : itinerary = null, createNew = true;

  final Itinerary? itinerary;
  final bool createNew;
}

class _ItineraryPickerSheet extends StatelessWidget {
  const _ItineraryPickerSheet({
    required this.itineraries,
    required this.destinationId,
  });

  final List<Itinerary> itineraries;
  final String destinationId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              l10n.addToItinerarySheetTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (itineraries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.addToItineraryEmpty,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  for (final itinerary in itineraries)
                    if (itinerary.destinations.contains(destinationId))
                      ListTile(
                        enabled: false,
                        leading: const Icon(
                          Icons.map_outlined,
                          color: Colors.white24,
                        ),
                        title: Text(
                          itinerary.title,
                          style: const TextStyle(color: Colors.white38),
                        ),
                        subtitle: Text(
                          l10n.addToItineraryAlreadyAdded,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.white38,
                          size: 18,
                        ),
                      )
                    else
                      ListTile(
                        leading: const Icon(
                          Icons.map_outlined,
                          color: Colors.white70,
                        ),
                        title: Text(
                          itinerary.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${itinerary.destinations.length}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_ItineraryChoice.existing(itinerary)),
                      ),
                  ListTile(
                    leading: Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      l10n.addToItineraryCreateNew,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const _ItineraryChoice.createNew()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
