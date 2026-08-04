import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/session_expired_card.dart';
import 'package:trip_io/widgets/skeleton_loaders.dart';

/// The "For You" home's counterpart on the account side: moderation notices
/// for destinations a user submitted, and reminders for trips starting
/// soon (see [SessionController.notifications], backed by
/// GET /me/notifications). In-app only - there's no push notification
/// infrastructure (Firebase/APNs) wired into this app, so these only ever
/// surface when someone opens the inbox themselves.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAndMarkAllRead();
  }

  // Returns the list as fetched (still carrying each item's original `read`
  // flag, so the unread dot renders for whatever was new when this page was
  // opened) while marking every currently-unread item read in the
  // background - opening the inbox is what clears the dashboard's badge
  // count, not needing to tap each entry one at a time.
  Future<List<AppNotification>> _loadAndMarkAllRead() async {
    final items = await widget.session.notifications();
    for (final n in items.where((n) => !n.read)) {
      unawaited(widget.session.markNotificationRead(n.id));
    }
    return items;
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.read) return;
    try {
      await widget.session.markNotificationRead(notification.id);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _future = widget.session.notifications();
    });
  }

  String _title(AppLocalizations l10n, AppNotification n) {
    switch (n.titleKey) {
      case 'notificationDestinationStatusTitle':
        return l10n.notificationDestinationStatusTitle;
      case 'notificationTripReminderTitle':
        return l10n.notificationTripReminderTitle;
      default:
        return n.titleKey;
    }
  }

  String _body(AppLocalizations l10n, AppNotification n) {
    final name = n.bodyArgs['name'] ?? '';
    final title = n.bodyArgs['title'] ?? '';
    final days = n.bodyArgs['days'];
    switch (n.bodyKey) {
      case 'notificationDestinationApprovedBody':
        return l10n.notificationDestinationApprovedBody(name);
      case 'notificationDestinationRejectedBody':
        return l10n.notificationDestinationRejectedBody(name);
      case 'notificationTripReminderBody':
        return days == '0'
            ? l10n.notificationTripReminderBodyToday(title)
            : l10n.notificationTripReminderBodyInDays(title, days ?? '0');
      default:
        return '';
    }
  }

  ({Color color, IconData icon}) _meta(AppNotification n) {
    if (n.type == 'trip_reminder') {
      return (color: const Color(0xFF1E88E5), icon: Icons.event_available);
    }
    if (n.bodyKey == 'notificationDestinationApprovedBody') {
      return (color: Colors.green.shade400, icon: Icons.check_circle);
    }
    if (n.bodyKey == 'notificationDestinationRejectedBody') {
      return (color: Colors.red.shade300, icon: Icons.cancel);
    }
    return (color: Colors.white70, icon: Icons.notifications);
  }

  Widget _buildCard(BuildContext context, AppLocalizations l10n, AppNotification n) {
    final meta = _meta(n);
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(n.createdAt);
    return GestureDetector(
      onTap: () => _markRead(n),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(14),
        style: n.read ? GlassPanelStyle.flat : GlassPanelStyle.blurred,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(meta.icon, color: meta.color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(l10n, n),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _body(l10n, n),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateLabel,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!n.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF2A93B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const double _backgroundBreakpoint = 700;

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
                        padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.notificationsTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.notificationsSubtitle,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            FutureBuilder<List<AppNotification>>(
                              future: _future,
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
                                    message: l10n.notificationsErrorMessage(
                                      snapshot.error.toString(),
                                    ),
                                  );
                                }
                                final items =
                                    snapshot.data ?? const <AppNotification>[];
                                if (items.isEmpty) {
                                  return EmptyStateCard(
                                    icon: Icons.notifications_none,
                                    title: l10n.notificationsEmptyTitle,
                                    subtitle: l10n.notificationsEmptySubtitle,
                                  );
                                }
                                return Column(
                                  children: items.map((n) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _buildCard(context, l10n, n),
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
                ),
              ),
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
