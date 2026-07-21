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
