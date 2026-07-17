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

        if (wide || medium) {
          return Scaffold(
            appBar: AppBar(title: Text(_labels[_index])),
            body: Row(
              children: [
                NavigationRail(
                  extended: wide,
                  selectedIndex: _index,
                  onDestinationSelected: (idx) => setState(() => _index = idx),
                  destinations: List.generate(_labels.length, (i) {
                    return NavigationRailDestination(
                      icon: Icon(_icons[i]),
                      label: Text(_labels[i]),
                    );
                  }),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_index]),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_labels[_index])),
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (idx) => setState(() => _index = idx),
            destinations: List.generate(_labels.length, (i) {
              return NavigationDestination(
                icon: Icon(_icons[i]),
                label: _labels[i],
              );
            }),
          ),
        );
      },
    );
  }
}
