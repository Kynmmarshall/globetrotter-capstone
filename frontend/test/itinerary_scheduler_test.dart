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

  group('generateMultiDaySchedule', () {
    test('single day behaves like generateSchedule', () {
      final tripStart = DateTime(2026, 1, 1);
      final result = generateMultiDaySchedule(
        destinationIds: ['d1', 'd2'],
        tripStart: tripStart,
        dayCount: 1,
        startHour: 9,
        startMinute: 0,
        dailyAvailable: const Duration(hours: 4),
      );
      final expected = generateSchedule(
        destinationIds: ['d1', 'd2'],
        start: DateTime(2026, 1, 1, 9, 0),
        totalAvailable: const Duration(hours: 4),
      );
      expect(result.entries.length, expected.length);
      expect(result.entries[0].start, expected[0].start);
      expect(result.entries[1].end, expected[1].end);
      expect(result.overrun, Duration.zero);
    });

    test('spreads destinations evenly across multiple days', () {
      final tripStart = DateTime(2026, 1, 1);
      final result = generateMultiDaySchedule(
        destinationIds: ['d1', 'd2', 'd3', 'd4'],
        tripStart: tripStart,
        dayCount: 2,
        startHour: 9,
        startMinute: 0,
        dailyAvailable: const Duration(hours: 4),
      );

      expect(result.entries.length, 4);
      // First 2 stops on day 1, next 2 on day 2, each day restarting at 9am.
      expect(result.entries[0].start.day, 1);
      expect(result.entries[1].start.day, 1);
      expect(result.entries[2].start.day, 2);
      expect(result.entries[3].start.day, 2);
      expect(result.entries[2].start.hour, 9);
    });

    test('empty destinations returns empty schedule', () {
      final result = generateMultiDaySchedule(
        destinationIds: [],
        tripStart: DateTime(2026, 1, 1),
        dayCount: 3,
        startHour: 9,
        startMinute: 0,
        dailyAvailable: const Duration(hours: 4),
      );
      expect(result.entries, isEmpty);
      expect(result.overrun, Duration.zero);
    });

    test('more days than destinations still schedules every stop', () {
      final result = generateMultiDaySchedule(
        destinationIds: ['d1'],
        tripStart: DateTime(2026, 1, 1),
        dayCount: 5,
        startHour: 9,
        startMinute: 0,
        dailyAvailable: const Duration(hours: 4),
      );
      expect(result.entries.length, 1);
      expect(result.entries.single.destinationId, 'd1');
    });
  });
}
