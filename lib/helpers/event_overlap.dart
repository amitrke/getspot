/// Events don't store an end time, so "overlap" is judged against an assumed
/// session length: two events whose start times are closer than this are
/// treated as overlapping. Sports meetups (badminton etc.) typically run
/// 1-2 hours, so 2h is a conservative default.
const Duration kAssumedEventDuration = Duration(hours: 2);

/// Minimal view of an existing event needed for the overlap check.
class EventSlot {
  final String name;
  final DateTime start;

  const EventSlot({required this.name, required this.start});
}

/// Returns the [existing] events that overlap a new event starting at
/// [newStart], sorted by start time.
///
/// Two events overlap when their start times are less than [duration] apart
/// (in either direction), i.e. each would still be running when the other
/// starts. Events exactly [duration] apart are back-to-back, not overlapping.
List<EventSlot> findOverlappingEvents(
  DateTime newStart,
  Iterable<EventSlot> existing, {
  Duration duration = kAssumedEventDuration,
}) {
  final overlapping = existing
      .where((e) => e.start.difference(newStart).abs() < duration)
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return overlapping;
}
