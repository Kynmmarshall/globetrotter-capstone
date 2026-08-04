import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/map_page.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/itinerary_scheduler.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/screens/itineraries_page.dart' show formatDuration;
import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/order_destinations_sheet.dart';

class ItineraryDetailPage extends StatelessWidget {
  const ItineraryDetailPage({
    super.key,
    required this.itinerary,
    required this.destinationsById,
    required this.session,
  });

  final Itinerary itinerary;
  final Map<String, Destination> destinationsById;
  final SessionController session;

  static const double _backgroundBreakpoint = 700;

  Future<void> _startItinerary(BuildContext context) async {
    final orderedIds = await showOrderDestinationsSheet(
      context,
      destinationIds: itinerary.destinations,
      destinationsById: destinationsById,
    );
    if (orderedIds == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPage(
          session: session,
          showAppBar: true,
          itineraryTitle: itinerary.title,
          itineraryDestinationIds: orderedIds,
        ),
      ),
    );
  }

  Future<void> _shareItinerary(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    String shareToken;
    try {
      shareToken = await session.shareItinerary(itinerary.id);
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.shareItineraryErrorSnackbar)),
      );
      return;
    }
    if (!context.mounted) return;

    final shareUrl = ApiClient.resolveShareUrl(shareToken);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.shareItineraryDialogTitle(itinerary.title)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shareItineraryDialogMessage),
            const SizedBox(height: 14),
            SelectableText(
              shareUrl,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await session.unshareItinerary(itinerary.id);
              } catch (_) {
                return;
              }
              if (!context.mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.shareItineraryTurnedOffSnackbar)),
              );
            },
            child: Text(l10n.shareItineraryTurnOffButton),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareUrl));
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.shareItineraryLinkCopiedSnackbar)),
              );
            },
            child: Text(l10n.shareItineraryCopyLinkButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.closeButton),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final schedule = itinerary.schedule;
    final totalDuration = schedule.isEmpty
        ? Duration.zero
        : schedule.last.end.difference(schedule.first.start);
    final startDate = itinerary.startDate;
    final endDate = itinerary.endDate;
    final dateFormat = MaterialLocalizations.of(context);
    String? dateRangeLabel;
    if (startDate != null && endDate != null) {
      dateRangeLabel = startDate == endDate
          ? dateFormat.formatMediumDate(startDate)
          : '${dateFormat.formatMediumDate(startDate)} – '
                '${dateFormat.formatMediumDate(endDate)}';
    }
    return GlassPanel(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itinerary.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.itineraryStopsSummary(
              itinerary.destinations.length.toString(),
              formatDuration(totalDuration),
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          if (dateRangeLabel != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  dateRangeLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
            ),
          ],
          if (itinerary.destinations.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startItinerary(context),
                icon: const Icon(Icons.navigation),
                label: Text(l10n.startItineraryButton),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, Destination? destination) {
    final imageUrl = ApiClient.resolveAssetUrl(destination?.imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Colors.white10,
                  child: Icon(Icons.place, color: Colors.white38, size: 22),
                ),
              )
            : const ColoredBox(
                color: Colors.white10,
                child: Icon(Icons.place, color: Colors.white38, size: 22),
              ),
      ),
    );
  }

  Widget _buildTravelConnector(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 2,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Icon(
            Icons.directions_walk,
            size: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            '${l10n.itineraryTravelTime}: ${formatDuration(travelBuffer)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, AppLocalizations l10n) {
    final schedule = itinerary.schedule;
    if (schedule.isEmpty) {
      return GlassPanel(
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.itineraryNoSchedule,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: itinerary.destinations.map((id) {
                final name = destinationsById[id]?.name ?? id;
                return Chip(
                  label: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    final timeFormat = MaterialLocalizations.of(context);
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final multiDay =
        schedule.isNotEmpty &&
        !isSameDay(schedule.first.start, schedule.last.start);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < schedule.length; i++) ...[
          if (multiDay &&
              (i == 0 ||
                  !isSameDay(schedule[i].start, schedule[i - 1].start))) ...[
            if (i > 0) const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                timeFormat.formatMediumDate(schedule[i].start),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ] else if (i > 0)
            _buildTravelConnector(context, l10n),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GlassPanel(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildThumbnail(
                            context,
                            destinationsById[schedule[i].destinationId],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${timeFormat.formatTimeOfDay(TimeOfDay.fromDateTime(schedule[i].start))} – '
                                  '${timeFormat.formatTimeOfDay(TimeOfDay.fromDateTime(schedule[i].end))}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  destinationsById[schedule[i].destinationId]
                                          ?.name ??
                                      schedule[i].destinationId,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        destinationsById[schedule[i]
                                                    .destinationId]
                                                ?.location ??
                                            destinationsById[schedule[i]
                                                    .destinationId]
                                                ?.country ??
                                            '',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompactBackground =
              constraints.maxWidth < _backgroundBreakpoint;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isCompactBackground
                    ? 'assets/backgrounds/mobile.png'
                    : 'assets/backgrounds/pc.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: context.tripColors.scrim),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context, l10n),
                            const SizedBox(height: 18),
                            Text(
                              l10n.itineraryPlanSectionTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildTimeline(context, l10n),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassPanel(
                        borderRadius: BorderRadius.circular(999),
                        padding: EdgeInsets.zero,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                        ),
                      ),
                      GlassPanel(
                        borderRadius: BorderRadius.circular(999),
                        padding: EdgeInsets.zero,
                        child: IconButton(
                          onPressed: () => _shareItinerary(context),
                          icon: const Icon(
                            Icons.ios_share,
                            color: Colors.white,
                          ),
                          tooltip: l10n.shareItineraryTooltip,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
