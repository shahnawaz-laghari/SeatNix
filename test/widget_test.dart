import 'package:flutter_test/flutter_test.dart';

import 'package:seatnix/services/departure_schedule.dart';

void main() {
  group('departuresFor', () {
    test('returns only future departures for the given day', () {
      final day = DateTime(2026, 11, 16);
      final now = DateTime(2026, 11, 16, 11, 30);

      final departures = departuresFor(day, now);

      expect(departureHours, [6, 10, 14, 18, 22]);
      expect(departures, [
        DateTime(2026, 11, 16, 14),
        DateTime(2026, 11, 16, 18),
        DateTime(2026, 11, 16, 22),
      ]);
    });

    test('returns all departures when the day is in the future', () {
      final day = DateTime(2026, 11, 17);
      final now = DateTime(2026, 11, 16, 20);

      final departures = departuresFor(day, now);

      expect(departures.length, 5);
    });
  });

  group('formatDepartureTime', () {
    test('formats morning, noon and evening times', () {
      expect(formatDepartureTime(DateTime(2026, 11, 16, 6)), '6:00 AM');
      expect(formatDepartureTime(DateTime(2026, 11, 16, 12)), '12:00 PM');
      expect(formatDepartureTime(DateTime(2026, 11, 16, 22, 5)), '10:05 PM');
    });
  });
}
