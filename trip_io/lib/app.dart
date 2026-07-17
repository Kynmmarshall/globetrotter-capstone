import 'package:flutter/material.dart';

import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/screens/auth_screen.dart';
import 'package:trip_io/screens/dashboard_screen.dart';
import 'package:trip_io/themes/theme.dart';

class TripIoApp extends StatefulWidget {
  const TripIoApp({super.key});

  @override
  State<TripIoApp> createState() => _TripIoAppState();
}

class _TripIoAppState extends State<TripIoApp> {
  final SessionController _session = SessionController();

  @override
  void initState() {
    super.initState();
    _session.initialize();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return MaterialApp(
          title: 'GlobeTrotter',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (!_session.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_session.isAuthenticated) {
      return AuthScreen(session: _session);
    }
    return DashboardScreen(session: _session);
  }
}

