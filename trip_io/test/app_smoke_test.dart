import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_io/app.dart';

void main() {
  testWidgets('TripIoApp renders', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const TripIoApp());
    await tester.pumpAndSettle();
    expect(find.text('GlobeTrotter'), findsOneWidget);
  });
}
