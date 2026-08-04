import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/destination_detail_page.dart';
import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/session_expired_card.dart';
import 'package:trip_io/widgets/skeleton_loaders.dart';

/// Lists every destination a user has suggested via [SubmitDestinationPage],
/// alongside its moderation status - previously a submission vanished into
/// a black box the moment it was sent, with no way to tell whether an admin
/// had approved, rejected or not yet looked at it.
class MySubmissionsPage extends StatefulWidget {
  const MySubmissionsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<MySubmissionsPage> createState() => _MySubmissionsPageState();
}

class _MySubmissionsPageState extends State<MySubmissionsPage> {
  late Future<List<Destination>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.session.mySubmissions();
  }

  Widget _buildThumbnail(Destination item) {
    final imageUrl = ApiClient.resolveAssetUrl(item.imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
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

  ({Color color, IconData icon, String label}) _statusMeta(
    AppLocalizations l10n,
    String status,
  ) {
    switch (status) {
      case 'approved':
        return (
          color: Colors.green.shade400,
          icon: Icons.check_circle,
          label: l10n.submissionStatusApproved,
        );
      case 'rejected':
        return (
          color: Colors.red.shade300,
          icon: Icons.cancel,
          label: l10n.submissionStatusRejected,
        );
      default:
        return (
          color: const Color(0xFFF2A93B),
          icon: Icons.hourglass_top,
          label: l10n.submissionStatusPending,
        );
    }
  }

  Widget _buildCard(BuildContext context, Destination item) {
    final l10n = AppLocalizations.of(context)!;
    final status = _statusMeta(l10n, item.status);
    final isApproved = item.status == 'approved';

    final card = GlassPanel(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
                        item.location ?? item.country,
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
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 14, color: status.color),
                    const SizedBox(width: 5),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isApproved)
            const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );

    if (!isApproved) return card;

    final heroTag = 'submission-${item.id}';
    return GestureDetector(
      onTap: () {
        Analytics.instance.trackEvent('destination', 'view', name: item.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailPage(
              destination: item,
              heroTag: heroTag,
              session: widget.session,
            ),
          ),
        );
      },
      child: card,
    );
  }

  static const double _backgroundBreakpoint = 700;

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mySubmissionsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.mySubmissionsSubtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Destination>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const DestinationListSkeleton();
                    }
                    if (snapshot.hasError) {
                      if (isAuthError(snapshot.error!)) {
                        return SessionExpiredCard(session: widget.session);
                      }
                      return ErrorStateCard(
                        message: l10n.mySubmissionsErrorMessage(
                          snapshot.error.toString(),
                        ),
                      );
                    }
                    final items = snapshot.data ?? <Destination>[];
                    if (items.isEmpty) {
                      return EmptyStateCard(
                        icon: Icons.add_location_alt_outlined,
                        title: l10n.mySubmissionsEmptyTitle,
                        subtitle: l10n.mySubmissionsEmptySubtitle,
                      );
                    }
                    return Column(
                      children: items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCard(context, item),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
              SafeArea(child: _buildBody(context, l10n)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GlassPanel(
                      borderRadius: BorderRadius.circular(999),
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
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
