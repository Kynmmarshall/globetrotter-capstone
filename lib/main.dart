import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() {
  // Wraps startup in a guarded zone so any async error that isn't already
  // caught by a FutureBuilder/try-catch (e.g. from a stray unawaited
  // Future) is logged instead of surfacing as a top-level isolate error.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Loads ICU date-formatting data for all supported locales (en, fr)
      // so DateFormat (used for the profile's "member since" date) doesn't
      // throw when formatting in a locale other than the default.
      await initializeDateFormatting();
      runApp(const TripIoApp());
    },
    (error, stack) {
      debugPrint('Uncaught async error: $error\n$stack');
    },
  );
}
