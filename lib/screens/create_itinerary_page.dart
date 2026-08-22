import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/itinerary_scheduler.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/utils/duration_format.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/price_tier_tag.dart';
import 'package:trip_io/widgets/session_expired_card.dart';
import 'package:trip_io/widgets/skeleton_loaders.dart';

/// Dedicated creation screen for a new itinerary - pushed via [Navigator]
/// (matching submit_destination_page.dart's convention) rather than living
/// inline in ItinerariesPage. Shared by both places that can start a new
/// itinerary: the Itineraries tab's "New itinerary" button, and a
/// destination card's "add to itinerary" -> "create new" (via
/// [initialDestinationId], which pre-selects that destination so the flow
/// always generates a real schedule instead of an empty one). Pops with the
/// created [Itinerary] on success so the caller decides what happens next.
class CreateItineraryPage extends StatefulWidget {
  const CreateItineraryPage({
    super.key,
    required this.session,
    this.initialDestinationId,
  });

  final SessionController session;
  final String? initialDestinationId;

  @override
  State<CreateItineraryPage> createState() => _CreateItineraryPageState();
}

class _CreateItineraryPageState extends State<CreateItineraryPage> {
  static const double _backgroundBreakpoint = 700;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationSearchController = TextEditingController();
  late final Set<String> _selectedDestinationIds;
  late final Future<List<Destination>> _destinationsFuture;
  bool _creating = false;
  bool _showAllDestinations = false;
  bool _destinationsTouched = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  double _availableHours = 4;
  DateTimeRange? _tripDates;

  bool get _tripSpansMultipleDays {
    final dates = _tripDates;
    return dates != null && dates.end.difference(dates.start).inDays > 0;
  }

  @override
  void initState() {
    super.initState();
    _selectedDestinationIds = {
      if (widget.initialDestinationId != null) widget.initialDestinationId!,
    };
    _destinationsFuture = widget.session.destinations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationSearchController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final titleValid = _formKey.currentState!.validate();
    final hasDestinations = _selectedDestinationIds.isNotEmpty;
    if (!hasDestinations) setState(() => _destinationsTouched = true);
    if (!titleValid || !hasDestinations || _creating) return;

    setState(() => _creating = true);
    try {
      final title = _titleController.text.trim();
      final destinationIds = _selectedDestinationIds.toList();
      final totalAvailable = Duration(
        minutes: (_availableHours * 60).round(),
      );
      final tripStart = _tripDates?.start ?? DateTime.now();
      final tripEnd = _tripDates?.end ?? tripStart;
      final dayCount = tripEnd.difference(tripStart).inDays + 1;
      final result = generateMultiDaySchedule(
        destinationIds: destinationIds,
        tripStart: tripStart,
        dayCount: dayCount,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        dailyAvailable: totalAvailable,
      );

      final created = await widget.session.createItinerary(
        title,
        destinationIds,
        schedule: result.entries,
        startDate: _tripDates?.start,
        endDate: _tripDates?.end,
      );
      if (!mounted) return;
      if (result.overrun > Duration.zero) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.itineraryOverrunWarning(
                formatDuration(result.overrun),
                minStopDuration.inMinutes.toString(),
              ),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      if (isAuthError(e)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.sessionExpiredTitle)));
        await widget.session.logout();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _selectedChip(Destination d) {
    return Chip(
      label: Text(
        d.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      avatar: const Icon(Icons.check, size: 16, color: Colors.white),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.85),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      onDeleted: () => setState(() => _selectedDestinationIds.remove(d.id)),
      deleteIconColor: Colors.white70,
    );
  }

  Widget _destinationTile(Destination d) {
    final imageUrl = ApiClient.resolveAssetUrl(d.imageUrl);
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() {
          _selectedDestinationIds.add(d.id);
          _destinationsTouched = false;
        }),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                                color: Colors.white10,
                                child: Icon(
                                  Icons.place,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                              ),
                        )
                      : const ColoredBox(
                          color: Colors.white10,
                          child: Icon(
                            Icons.place,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.country,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        if (d.priceTier != null) ...[
                          const SizedBox(width: 6),
                          PriceTierTag(priceTier: d.priceTier!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.add_circle_outline,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Candidates a user can still add: everything not already selected,
  // narrowed down either by the search box or by "show all" - the full
  // 60+ destination list never renders unfiltered by default.
  List<Destination> _destinationCandidates(List<Destination> all) {
    final unselected = all.where(
      (d) => !_selectedDestinationIds.contains(d.id),
    );
    if (_showAllDestinations) return unselected.toList();
    final query = _destinationSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return unselected
        .where((d) => d.name.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildDestinationPicker(
    AppLocalizations l10n,
    List<Destination> destinations,
  ) {
    final byId = {for (final d in destinations) d.id: d};
    final selected = _selectedDestinationIds
        .map((id) => byId[id])
        .whereType<Destination>()
        .toList();
    final candidates = _destinationCandidates(destinations);
    final query = _destinationSearchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map(_selectedChip).toList(),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _destinationSearchController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: _fieldDecoration(l10n.itineraryDestinationSearchHint)
              .copyWith(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _showAllDestinations = !_showAllDestinations),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              _showAllDestinations ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: Colors.white70,
            ),
            label: Text(
              _showAllDestinations
                  ? l10n.itineraryHideAllDestinations
                  : l10n.itineraryShowAllDestinations(destinations.length),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (candidates.isEmpty)
          Text(
            _showAllDestinations
                ? l10n.itineraryAllDestinationsAdded
                : (query.isEmpty
                      ? l10n.itineraryDestinationSearchPrompt
                      : l10n.itineraryDestinationSearchNoMatches(query)),
            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
          )
        else
          Column(
            children: [
              for (var i = 0; i < candidates.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _destinationTile(candidates[i]),
              ],
            ],
          ),
        if (_destinationsTouched && _selectedDestinationIds.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.itineraryDestinationsRequired,
            style: TextStyle(color: Colors.red.shade200, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickTripDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      initialDateRange: _tripDates ?? DateTimeRange(start: today, end: today),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _tripDates = picked);
    }
  }

  Widget _buildTripDatesInput(AppLocalizations l10n) {
    final dateFormat = MaterialLocalizations.of(context);
    final dates = _tripDates;
    final label = dates == null
        ? l10n.tripDatesHint
        : dates.start == dates.end
        ? dateFormat.formatMediumDate(dates.start)
        : '${dateFormat.formatMediumDate(dates.start)} – '
              '${dateFormat.formatMediumDate(dates.end)}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickTripDates,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 18, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: dates == null ? Colors.white60 : Colors.white,
                  fontSize: 13.5,
                ),
              ),
            ),
            const Icon(Icons.edit, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  // Three visually distinct groups (Dates / Start time / Available time)
  // instead of the old bundle under one ambiguous "Trip dates" label - the
  // day count is now surfaced live under the date picker instead of being
  // silently implied by generateMultiDaySchedule's math.
  Widget _buildTripTiming(AppLocalizations l10n) {
    final timeLabel = _startTime.format(context);
    final durationLabel = formatDuration(
      Duration(minutes: (_availableHours * 60).round()),
    );
    final dates = _tripDates;
    final dayCount = dates == null
        ? 1
        : dates.end.difference(dates.start).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l10n.tripDatesLabel),
        const SizedBox(height: 8),
        _buildTripDatesInput(l10n),
        const SizedBox(height: 6),
        Text(
          dates == null
              ? l10n.itineraryDayCountToday
              : l10n.itineraryDayCountLabel(dayCount),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _pickStartTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.itineraryStartTime(timeLabel),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                ),
                const Icon(Icons.edit, size: 16, color: Colors.white54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _tripSpansMultipleDays
              ? l10n.itineraryAvailableTimePerDay(durationLabel)
              : l10n.itineraryAvailableTime(durationLabel),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.15),
            valueIndicatorColor: Theme.of(context).colorScheme.primary,
          ),
          child: Slider(
            value: _availableHours,
            min: 1,
            max: 12,
            divisions: 22,
            label: durationLabel,
            onChanged: (value) => setState(() => _availableHours = value),
          ),
        ),
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
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                GlassPanel(
                                  borderRadius: BorderRadius.circular(999),
                                  padding: EdgeInsets.zero,
                                  child: IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GlassPanel(
                              borderRadius: BorderRadius.circular(22),
                              padding: const EdgeInsets.all(18),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.itinerariesPlanTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _titleController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white,
                                      decoration: _fieldDecoration(
                                        l10n.itineraryTitleLabel,
                                        hint: l10n.itineraryTitleHint,
                                      ),
                                      validator: (value) =>
                                          (value == null ||
                                              value.trim().isEmpty)
                                          ? l10n.itineraryTitleRequired
                                          : null,
                                    ),
                                    const SizedBox(height: 18),
                                    _sectionLabel(l10n.destinationsLabel),
                                    const SizedBox(height: 8),
                                    FutureBuilder<List<Destination>>(
                                      future: _destinationsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const DestinationListSkeleton(
                                            itemCount: 3,
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          if (isAuthError(snapshot.error!)) {
                                            return SessionExpiredCard(
                                              session: widget.session,
                                            );
                                          }
                                          return ErrorStateCard(
                                            message: l10n.destinationsLoadError(
                                              snapshot.error.toString(),
                                            ),
                                          );
                                        }
                                        final destinations =
                                            snapshot.data ?? <Destination>[];
                                        if (destinations.isEmpty) {
                                          return Text(
                                            l10n.noDestinationsAvailable,
                                            style: const TextStyle(
                                              color: Colors.white60,
                                            ),
                                          );
                                        }
                                        return _buildDestinationPicker(
                                          l10n,
                                          destinations,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTripTiming(l10n),
                                    const SizedBox(height: 20),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: _creating ? null : _create,
                                        icon: _creating
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.map, size: 18),
                                        label: Text(l10n.createItineraryButton),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
