import 'package:flutter_test/flutter_test.dart';
import 'package:kalis/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('adds calendar days across a daylight-saving transition', () {
      final transitionDay = DateTime(2026, 10, 25);
      final days = List.generate(4, transitionDay.addCalendarDays);

      expect(days.map((date) => date.day), [25, 26, 27, 28]);
      expect(days.map((date) => date.hour), [0, 0, 0, 0]);
    });

    test('counts three calendar days despite a 24-hour boundary shift', () {
      final lastTraining = DateTime(2026, 10, 25);
      final referenceDay = DateTime(2026, 10, 28, 23);

      expect(referenceDay.daysFrom(lastTraining), 3);
    });
  });
}
