import 'package:trip_io/models/models.dart';

/// Minimum time given to each stop, even if that means the generated plan
/// runs longer than the traveller's requested budget (better than a
/// pointless few-minute "visit").
const Duration minStopDuration = Duration(minutes: 20);

/// Buffer reserved for getting from one stop to the next.
const Duration travelBuffer = Duration(minutes: 20);

/// Splits [totalAvailable] starting at [start] evenly across
/// [destinationIds], leaving [travelBuffer] between consecutive stops.
///
/// Pure and deterministic: same inputs always produce the same plan, which
/// keeps it easy to preview client-side and to unit test.
List<ScheduleEntry> generateSchedule({
  required List<String> destinationIds,
  required DateTime start,
  required Duration totalAvailable,
}) {
  if (destinationIds.isEmpty) {
    return [];
  }

  final stopCount = destinationIds.length;
  final totalBuffer = travelBuffer * (stopCount - 1);
  final rawStopDuration = (totalAvailable - totalBuffer) ~/ stopCount;
  final stopDuration = rawStopDuration < minStopDuration
      ? minStopDuration
      : rawStopDuration;

  var cursor = start;
  final entries = <ScheduleEntry>[];
  for (var i = 0; i < stopCount; i++) {
    final stopStart = cursor;
    final stopEnd = stopStart.add(stopDuration);
    entries.add(
      ScheduleEntry(
        destinationId: destinationIds[i],
        start: stopStart,
        end: stopEnd,
      ),
    );
    cursor = stopEnd.add(travelBuffer);
  }
  return entries;
}

/// Combined result of [generateMultiDaySchedule]: the stop-by-stop plan
/// spread across every day, plus how far the worst single day overran its
/// daily budget (zero if every day fit).
class MultiDaySchedule {
  MultiDaySchedule({required this.entries, required this.overrun});

  final List<ScheduleEntry> entries;
  final Duration overrun;
}

/// Spreads [destinationIds] evenly across [dayCount] consecutive days
/// starting at [tripStart] (only its date component is used), each day
/// reusing [generateSchedule] with its own [dailyAvailable] budget starting
/// at [startHour]:[startMinute].
///
/// [dayCount] < 1 is treated as a single day, so a same-day trip behaves
/// exactly like calling [generateSchedule] directly.
MultiDaySchedule generateMultiDaySchedule({
  required List<String> destinationIds,
  required DateTime tripStart,
  required int dayCount,
  required int startHour,
  required int startMinute,
  required Duration dailyAvailable,
}) {
  if (destinationIds.isEmpty) {
    return MultiDaySchedule(entries: const [], overrun: Duration.zero);
  }

  final effectiveDayCount = dayCount < 1 ? 1 : dayCount;
  final stopsPerDay = (destinationIds.length / effectiveDayCount).ceil();

  final entries = <ScheduleEntry>[];
  var maxOverrun = Duration.zero;
  var index = 0;
  for (
    var day = 0;
    day < effectiveDayCount && index < destinationIds.length;
    day++
  ) {
    final dayDate = tripStart.add(Duration(days: day));
    final dayStart = DateTime(
      dayDate.year,
      dayDate.month,
      dayDate.day,
      startHour,
      startMinute,
    );
    final chunk = destinationIds.skip(index).take(stopsPerDay).toList();
    index += chunk.length;

    final daySchedule = generateSchedule(
      destinationIds: chunk,
      start: dayStart,
      totalAvailable: dailyAvailable,
    );
    entries.addAll(daySchedule);

    if (daySchedule.isNotEmpty) {
      final dayOverrun = daySchedule.last.end.difference(
        dayStart.add(dailyAvailable),
      );
      if (dayOverrun > maxOverrun) {
        maxOverrun = dayOverrun;
      }
    }
  }
  return MultiDaySchedule(entries: entries, overrun: maxOverrun);
}
