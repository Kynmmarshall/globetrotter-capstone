import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads ICU date-formatting data for all supported locales (en, fr) so
  // DateFormat (used for the profile's "member since" date) doesn't throw
  // when formatting in a locale other than the default.
  await initializeDateFormatting();
  runApp(const TripIoApp());
}
