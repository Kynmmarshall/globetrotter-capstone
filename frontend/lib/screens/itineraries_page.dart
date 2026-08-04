import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/itinerary_detail_page.dart';
import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/itinerary_scheduler.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/session_expired_card.dart';

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ItinerariesPage> createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  final _titleController = TextEditingController();
  final _destinationSearchController = TextEditingController();
  final Set<String> _selectedDestinationIds = {};
  late Future<List<Itinerary>> _future;
  late Future<List<Destination>> _destinationsFuture;
  bool _creating = false;
  bool _showAllDestinations = false;
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
    _future = widget.session.itineraries();
    _destinationsFuture = widget.session.destinations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationSearchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.session.itineraries();
    });
  }

  Future<void> _deleteItinerary(Itinerary item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteItineraryConfirmTitle),
        content: Text(l10n.deleteItineraryConfirmMessage(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: Text(l10n.deleteItineraryButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.session.deleteItinerary(item.id);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.itineraryDeletedSnackbar)));
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
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDestinationIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.itinerariesFormMissing)));
      return;
    }

    setState(() => _creating = true);
    try {
      final destinationIds = _selectedDestinationIds.toList();
      final totalAvailable = Duration(minutes: (_availableHours * 60).round());
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
      final schedule = result.entries;
      final overrun = result.overrun;

      await widget.session.createItinerary(
        title,
        destinationIds,
        schedule: schedule,
        startDate: _tripDates?.start,
        endDate: _tripDates?.end,
      );
      _titleController.clear();
      setState(() {
        _selectedDestinationIds.clear();
        _tripDates = null;
      });
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.itineraryCreatedSnackbar)));
      if (overrun > Duration.zero) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.itineraryOverrunWarning(
                formatDuration(overrun),
                minStopDuration.inMinutes.toString(),
              ),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
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

  Widget _destinationChip(Destination d, ColorScheme colors) {
    final selected = _selectedDestinationIds.contains(d.id);
    return FilterChip(
      label: Text(
        d.name,
        style: TextStyle(
          color: selected
              ? Colors.white
              : const Color.fromARGB(255, 96, 193, 177).withValues(alpha: 0.92),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedDestinationIds.add(d.id);
          } else {
            _selectedDestinationIds.remove(d.id);
          }
        });
      },
      showCheckmark: false,
      avatar: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
      backgroundColor: Colors.white.withValues(alpha: 0.14),
      selectedColor: colors.primary.withValues(alpha: 0.85),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
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

  Widget _buildDestinationPicker(List<Destination> destinations) {
    final l10n = AppLocalizations.of(context)!;
    if (destinations.isEmpty) {
      return Text(
        l10n.noDestinationsAvailable,
        style: const TextStyle(color: Colors.white60),
      );
    }
    final colors = Theme.of(context).colorScheme;
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
            children: selected.map((d) => _destinationChip(d, colors)).toList(),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: candidates
                .map((d) => _destinationChip(d, colors))
                .toList(),
          ),
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

  Widget _buildTimeInputs(AppLocalizations l10n) {
    final timeLabel = _startTime.format(context);
    final durationLabel = formatDuration(
      Duration(minutes: (_availableHours * 60).round()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tripDatesLabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildTripDatesInput(l10n),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
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

  Widget _buildCreateForm(List<Destination> destinations) {
    final l10n = AppLocalizations.of(context)!;
    return GlassPanel(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.itinerariesPlanTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: _fieldDecoration(
              l10n.itineraryTitleLabel,
              hint: l10n.itineraryTitleHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.destinationsLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildDestinationPicker(destinations),
          const SizedBox(height: 16),
          _buildTimeInputs(l10n),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _creating ? null : _create,
              child: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.createItineraryButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationTag(String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildItinerariesList(Map<String, Destination> destinationsById) {
    return FutureBuilder<List<Itinerary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.hasError) {
          if (isAuthError(snapshot.error!)) {
            return SessionExpiredCard(session: widget.session);
          }
          return ErrorStateCard(
            message: l10n.itinerariesErrorMessage(snapshot.error.toString()),
          );
        }
        final items = snapshot.data ?? <Itinerary>[];
        if (items.isEmpty) {
          return EmptyStateCard(
            icon: Icons.map_outlined,
            title: l10n.itinerariesEmptyTitle,
            subtitle: l10n.itinerariesEmptySubtitle,
          );
        }
        return Column(
          children: items.map((item) {
            final names = item.destinations
                .map((id) => destinationsById[id]?.name ?? id)
                .toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                button: true,
                label: l10n.itineraryCardSemanticLabel(item.title),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Analytics.instance.trackEvent(
                        'itinerary',
                        'view',
                        name: item.id,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ItineraryDetailPage(
                            itinerary: item,
                            destinationsById: destinationsById,
                            session: widget.session,
                          ),
                        ),
                      );
                    },
                    child: GlassPanel(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.tertiary,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.map,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteItinerary(item),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.deleteItineraryButton,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: names.map(_buildDestinationTag).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Destination>>(
        future: _destinationsFuture,
        builder: (context, destSnapshot) {
          final l10n = AppLocalizations.of(context)!;
          if (destSnapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (destSnapshot.hasError) {
            if (isAuthError(destSnapshot.error!)) {
              return SessionExpiredCard(session: widget.session);
            }
            return ErrorStateCard(
              message: l10n.destinationsLoadError(
                destSnapshot.error.toString(),
              ),
            );
          }
          final destinations = destSnapshot.data ?? <Destination>[];
          final destinationsById = {for (final d in destinations) d.id: d};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCreateForm(destinations),
              const SizedBox(height: 20),
              Text(
                l10n.yourItinerariesTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildItinerariesList(destinationsById),
            ],
          );
        },
      ),
    );
  }
}
