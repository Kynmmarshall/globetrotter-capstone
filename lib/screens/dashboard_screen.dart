import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/services/analytics.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/screens/destinations_page.dart';
import 'package:trip_io/screens/favorites_page.dart';
import 'package:trip_io/screens/itineraries_page.dart';
import 'package:trip_io/screens/profile_page.dart';
import 'package:trip_io/screens/recommendations_page.dart';
import 'package:trip_io/widgets/ai_chat_sheet.dart';
import 'package:trip_io/widgets/ai_fab_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _icons = <IconData>[
    Icons.public,
    Icons.star,
    Icons.favorite,
    Icons.map,
    Icons.person,
  ];
  static const double _backgroundBreakpoint = 700;
  // Locale-independent identifiers for analytics, distinct from the
  // user-facing (translated) tab labels below.
  static const _screenNames = <String>[
    'destinations',
    'recommendations',
    'favorites',
    'itineraries',
    'profile',
  ];

  // Web and mobile get a menu-icon-triggered drawer instead of a
  // permanently-visible side rail - only the native Windows desktop build
  // keeps the always-on NavigationRail/NavigationBar responsive layout,
  // where the extra chrome doesn't compete with limited screen space.
  bool get _useDrawerNav =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    Analytics.instance.trackScreen(_screenNames[_index]);
  }

  void _selectTab(int index) {
    setState(() => _index = index);
    Analytics.instance.trackScreen(_screenNames[index]);
  }

  List<String> _labels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.navDestinations,
      l10n.navRecommendations,
      l10n.navFavorites,
      l10n.navItineraries,
      l10n.navProfile,
    ];
  }

  // A fixed (non-draggable) shortcut into the AI chat, available from every
  // dashboard tab as an overlay sheet rather than a nav item - asking the
  // AI something no longer means navigating away from what you're browsing.
  Widget _aiFab(BuildContext context) {
    return AiFabButton(onTap: () => showAiChatSheet(context, session: widget.session));
  }

  Widget _frostedSurface({required Widget child, double blur = 18, double alpha = 0.16}) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: alpha)),
          child: child,
        ),
      ),
    );
  }

  Widget _navDrawer(List<String> labels) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: _frostedSurface(
        blur: 24,
        alpha: 0.2,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'trip_io',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              for (var i = 0; i < labels.length; i++)
                ListTile(
                  leading: Icon(
                    _icons[i],
                    color: _index == i ? Colors.white : Colors.white70,
                  ),
                  title: Text(
                    labels[i],
                    style: TextStyle(
                      color: _index == i ? Colors.white : Colors.white70,
                      fontWeight: _index == i ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  selected: _index == i,
                  selectedTileColor: Colors.white.withValues(alpha: 0.12),
                  onTap: () {
                    _selectTab(i);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DestinationsPage(session: widget.session),
      RecommendationsPage(session: widget.session),
      FavoritesPage(session: widget.session),
      ItinerariesPage(session: widget.session),
      ProfilePage(session: widget.session),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final medium = constraints.maxWidth >= 700;
        final isCompactBackground = constraints.maxWidth < _backgroundBreakpoint;
        final labels = _labels(context);

        final appBar = PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _frostedSurface(
            child: AppBar(
              title: Text(labels[_index]),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
        );

        Widget navRail() {
          return _frostedSurface(
            child: NavigationRail(
              extended: wide,
              backgroundColor: Colors.transparent,
              selectedIndex: _index,
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              onDestinationSelected: _selectTab,
              destinations: List.generate(labels.length, (i) {
                return NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  label: Text(labels[i]),
                );
              }),
            ),
          );
        }

        Widget bottomNav() {
          return _frostedSurface(
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.white.withValues(alpha: 0.22),
              selectedIndex: _index,
              onDestinationSelected: _selectTab,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                );
              }),
              destinations: List.generate(labels.length, (i) {
                return NavigationDestination(
                  icon: Icon(_icons[i], color: Colors.white70),
                  selectedIcon: Icon(_icons[i], color: Colors.white),
                  label: labels[i],
                );
              }),
            ),
          );
        }

        final Widget scaffold;
        if (_useDrawerNav) {
          // Web/mobile: no permanently-visible rail or bottom bar - just the
          // menu icon Scaffold automatically adds to the AppBar once a
          // `drawer` is set.
          scaffold = Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            drawer: _navDrawer(labels),
            body: pages[_index],
            floatingActionButton: _aiFab(context),
          );
        } else {
          final body = wide || medium
              ? Row(
                  children: [
                    navRail(),
                    const VerticalDivider(width: 1, color: Colors.white24),
                    Expanded(child: pages[_index]),
                  ],
                )
              : pages[_index];
          scaffold = Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: body,
            bottomNavigationBar: (!wide && !medium) ? bottomNav() : null,
            floatingActionButton: _aiFab(context),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              isCompactBackground ? 'assets/backgrounds/mobile.png' : 'assets/backgrounds/pc.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.58)),
            ),
            scaffold,
          ],
        );
      },
    );
  }
}
