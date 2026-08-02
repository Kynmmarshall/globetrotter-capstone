import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';

/// Opens a bottom sheet letting the user drag-reorder [destinationIds] into
/// the order they want to visit them in. Returns the reordered list, or
/// null if the user dismissed the sheet without confirming.
///
/// Shared by the itinerary detail page's "Start itinerary" flow and the map
/// screen's "select itinerary" mode - both need this same step before a
/// route/numbered markers can be built from an itinerary's destinations.
Future<List<String>?> showOrderDestinationsSheet(
  BuildContext context, {
  required List<String> destinationIds,
  required Map<String, Destination> destinationsById,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF13253A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _OrderDestinationsSheet(
      destinationIds: destinationIds,
      destinationsById: destinationsById,
    ),
  );
}

class _OrderDestinationsSheet extends StatefulWidget {
  const _OrderDestinationsSheet({
    required this.destinationIds,
    required this.destinationsById,
  });

  final List<String> destinationIds;
  final Map<String, Destination> destinationsById;

  @override
  State<_OrderDestinationsSheet> createState() =>
      _OrderDestinationsSheetState();
}

class _OrderDestinationsSheetState extends State<_OrderDestinationsSheet> {
  late final List<String> _order = List.of(widget.destinationIds);

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final id = _order.removeAt(oldIndex);
      _order.insert(newIndex, id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
              l10n.orderDestinationsSheetTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.orderDestinationsSheetSubtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: _order.length,
                onReorderItem: _onReorder,
                itemBuilder: (context, index) {
                  final id = _order[index];
                  final destination = widget.destinationsById[id];
                  return ListTile(
                    key: ValueKey(id),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      destination?.name ?? id,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle,
                        color: Colors.white54,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_order),
                child: Text(l10n.orderDestinationsConfirmButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
