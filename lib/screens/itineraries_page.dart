import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/session_expired_card.dart';

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ItinerariesPage> createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  final _titleController = TextEditingController();
  final Set<String> _selectedDestinationIds = {};
  late Future<List<Itinerary>> _future;
  late Future<List<Destination>> _destinationsFuture;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _future = widget.session.itineraries();
    _destinationsFuture = widget.session.destinations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.session.itineraries();
    });
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDestinationIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.itinerariesFormMissing)),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      await widget.session.createItinerary(title, _selectedDestinationIds.toList());
      _titleController.clear();
      setState(() => _selectedDestinationIds.clear());
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.itineraryCreatedSnackbar)));
    } catch (e) {
      if (!mounted) return;
      if (isAuthError(e)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sessionExpiredTitle)));
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

  Widget _glassPanel({required Widget child, EdgeInsets? padding, BorderRadius? borderRadius}) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
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

  Widget _buildDestinationPicker(List<Destination> destinations) {
    if (destinations.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noDestinationsAvailable,
        style: const TextStyle(color: Colors.white60),
      );
    }
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: destinations.map((d) {
        final selected = _selectedDestinationIds.contains(d.id);
        return FilterChip(
          label: Text(
            d.name,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.92),
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
          avatar: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          selectedColor: colors.primary.withValues(alpha: 0.85),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        );
      }).toList(),
    );
  }

  Widget _buildCreateForm(List<Destination> destinations) {
    final l10n = AppLocalizations.of(context)!;
    return _glassPanel(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.itinerariesPlanTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: _fieldDecoration(l10n.itineraryTitleLabel, hint: l10n.itineraryTitleHint),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.destinationsLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildDestinationPicker(destinations),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _creating ? null : _create,
              child: _creating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
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
          return ErrorStateCard(message: l10n.itinerariesErrorMessage(snapshot.error.toString()));
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
            final names = item.destinations.map((id) => destinationsById[id]?.name ?? id).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _glassPanel(
                borderRadius: BorderRadius.circular(16),
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
                          child: const Icon(Icons.map, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
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
            return ErrorStateCard(message: l10n.destinationsLoadError(destSnapshot.error.toString()));
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
