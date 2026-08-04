import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/screens/auth_screen.dart';
import 'package:trip_io/screens/dashboard_screen.dart';
import 'package:trip_io/screens/splash_screen.dart';
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
    // A shared-itinerary link opens this same web app with `?claim=<token>`
    // (see ApiClient.resolveShareUrl) - the token is read once here, off
    // the actual browser address bar, and carried in-session until
    // DashboardScreen claims it (immediately if already signed in, or
    // right after whoever opened the link creates an account).
    if (kIsWeb) {
      final claim = Uri.base.queryParameters['claim'];
      if (claim != null && claim.isNotEmpty) {
        _session.setPendingClaimToken(claim);
      }
    }
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
          title: 'trip_io',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.theme,
          themeMode: _session.themeMode,
          locale: _session.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (!_session.ready) {
      return const SplashScreen();
    }
    if (!_session.isAuthenticated) {
      // Whoever opened a claim link almost certainly doesn't have an
      // account yet - default to the register tab instead of login so
      // they're not stuck guessing they need to switch first.
      return AuthScreen(
        session: _session,
        initialLoginMode: _session.pendingClaimToken == null,
      );
    }
    return DashboardScreen(session: _session);
  }
}
