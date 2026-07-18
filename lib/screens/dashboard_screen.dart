import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/screens/destinations_page.dart';
import 'package:trip_io/screens/itineraries_page.dart';
import 'package:trip_io/screens/profile_page.dart';
import 'package:trip_io/screens/recommendations_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _labels = <String>['Destinations', 'Recommendations', 'Itineraries', 'Profile'];
  static const _icons = <IconData>[Icons.public, Icons.star, Icons.map, Icons.person];
  static const double _backgroundBreakpoint = 700;

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      DestinationsPage(session: widget.session),
      RecommendationsPage(session: widget.session),
      ItinerariesPage(session: widget.session),
      ProfilePage(session: widget.session),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final medium = constraints.maxWidth >= 700;
        final isCompactBackground = constraints.maxWidth < _backgroundBreakpoint;

        final appBar = PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _frostedSurface(
            child: AppBar(
              title: Text(_labels[_index]),
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
              onDestinationSelected: (idx) => setState(() => _index = idx),
              destinations: List.generate(_labels.length, (i) {
                return NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  label: Text(_labels[i]),
                );
              }),
            ),
          );
        }

        Widget bottomNav() {
          return _frostedSurface(
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: _index,
              onDestinationSelected: (idx) => setState(() => _index = idx),
              destinations: List.generate(_labels.length, (i) {
                return NavigationDestination(
                  icon: Icon(_icons[i], color: Colors.white70),
                  selectedIcon: Icon(_icons[i], color: Colors.white),
                  label: _labels[i],
                );
              }),
            ),
          );
        }

        final body = wide || medium
            ? Row(
                children: [
                  navRail(),
                  const VerticalDivider(width: 1, color: Colors.white24),
                  Expanded(child: pages[_index]),
                ],
              )
            : pages[_index];

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
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: appBar,
              body: body,
              bottomNavigationBar: (!wide && !medium) ? bottomNav() : null,
            ),
          ],
        );
      },
    );
  }
}
