import 'package:flutter_test/flutter_test.dart';
import 'package:getspot/helpers/event_overlap.dart';

void main() {
  final newStart = DateTime(2026, 11, 14, 18, 0);

  EventSlot slot(String name, DateTime start) =>
      EventSlot(name: name, start: start);

  group('findOverlappingEvents', () {
    test('returns empty when there are no existing events', () {
      expect(findOverlappingEvents(newStart, const []), isEmpty);
    });

    test('flags an event at the same time', () {
      final result =
          findOverlappingEvents(newStart, [slot('Badminton', newStart)]);
      expect(result.map((e) => e.name), ['Badminton']);
    });

    test('flags events within the assumed duration on either side', () {
      final result = findOverlappingEvents(newStart, [
        slot('earlier', newStart.subtract(const Duration(minutes: 90))),
        slot('later', newStart.add(const Duration(minutes: 119))),
      ]);
      expect(result.map((e) => e.name), ['earlier', 'later']);
    });

    test('treats events exactly the duration apart as back-to-back', () {
      final result = findOverlappingEvents(newStart, [
        slot('before', newStart.subtract(kAssumedEventDuration)),
        slot('after', newStart.add(kAssumedEventDuration)),
      ]);
      expect(result, isEmpty);
    });

    test('ignores events on the same day that are far apart', () {
      final result = findOverlappingEvents(newStart, [
        slot('morning', DateTime(2026, 11, 14, 8, 0)),
      ]);
      expect(result, isEmpty);
    });

    test('sorts results by start time', () {
      final result = findOverlappingEvents(newStart, [
        slot('b', newStart.add(const Duration(minutes: 30))),
        slot('a', newStart.subtract(const Duration(minutes: 30))),
      ]);
      expect(result.map((e) => e.name), ['a', 'b']);
    });

    test('honours a custom duration', () {
      final existing = [slot('x', newStart.add(const Duration(minutes: 45)))];
      expect(
        findOverlappingEvents(newStart, existing,
            duration: const Duration(minutes: 30)),
        isEmpty,
      );
      expect(
        findOverlappingEvents(newStart, existing,
            duration: const Duration(hours: 1)),
        hasLength(1),
      );
    });
  });
}
