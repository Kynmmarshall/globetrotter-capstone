import 'package:flutter_test/flutter_test.dart';
import 'package:trip_io/services/itinerary_scheduler.dart';

void main() {
  group('generateSchedule', () {
    test('returns empty list for no destinations', () {
      final result = generateSchedule(
        destinationIds: [],
        start: DateTime(2026, 1, 1, 9),
        totalAvailable: const Duration(hours: 4),
      );
      expect(result, isEmpty);
    });

    test('splits time evenly with travel buffers between stops', () {
      final start = DateTime(2026, 1, 1, 9, 0);
      final result = generateSchedule(
        destinationIds: ['d1', 'd2', 'd3', 'd4'],
        start: start,
        totalAvailable: const Duration(hours: 6),
      );

      expect(result.length, 4);
      // 360 min total - 3*20 min buffer = 300 min / 4 stops = 75 min/stop.
      expect(result[0].start, start);
      expect(result[0].end, start.add(const Duration(minutes: 75)));
      expect(result[1].start, result[0].end.add(travelBuffer));
      expect(result[1].end, result[1].start.add(const Duration(minutes: 75)));
      expect(result[3].destinationId, 'd4');

      // Stops never overlap and stay chronologically ordered.
      for (var i = 1; i < result.length; i++) {
        expect(result[i].start.isAfter(result[i - 1].end), isTrue);
      }
    });

    test('single destination gets the full available time, no buffer', () {
      final start = DateTime(2026, 1, 1, 9, 0);
      final result = generateSchedule(
        destinationIds: ['only'],
        start: start,
        totalAvailable: const Duration(hours: 2),
      );
      expect(result.length, 1);
      expect(result.single.start, start);
      expect(result.single.end, start.add(const Duration(hours: 2)));
    });

    test('floors stop duration at minStopDuration when time is too tight', () {
      final start = DateTime(2026, 1, 1, 9, 0);
      final result = generateSchedule(
        destinationIds: ['d1', 'd2', 'd3'],
        start: start,
        totalAvailable: const Duration(minutes: 30),
      );
      expect(result.length, 3);
      for (final entry in result) {
        expect(entry.duration, minStopDuration);
      }
      // The plan legitimately overruns the requested 30 minutes here -
      // callers are expected to compare result.last.end against the
      // requested budget and warn the user, rather than this function
      // silently producing unusably short visits.
      expect(result.last.end.isAfter(start.add(const Duration(minutes: 30))), isTrue);
    });
  });
}
