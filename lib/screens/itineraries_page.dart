import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/create_itinerary_page.dart';
import 'package:trip_io/screens/itinerary_detail_page.dart';
import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/session_expired_card.dart';

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ItinerariesPage> createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  late Future<List<Itinerary>> _future;
  late Future<List<Destination>> _destinationsFuture;

  @override
  void initState() {
    super.initState();
    _future = widget.session.itineraries();
    _destinationsFuture = widget.session.destinations();
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

  Future<void> _openCreatePage(Map<String, Destination> destinationsById) async {
    final created = await Navigator.of(context).push<Itinerary>(
      MaterialPageRoute(
        builder: (_) => CreateItineraryPage(session: widget.session),
      ),
    );
    if (created == null || !mounted) return;
    await _refresh();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItineraryDetailPage(
          itinerary: created,
          destinationsById: destinationsById,
          session: widget.session,
        ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.yourItinerariesTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openCreatePage(destinationsById),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.newItineraryButton),
                  ),
                ],
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
