import 'package:carpe_diem/core/utils/deadline_urgency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeadlineUrgency.of', () {
    final today = DateTime(2026, 11, 8);

    DeadlineUrgency inDays(int days) =>
        DeadlineUrgency.of(DateTime(2026, 11, 8 + days), today);

    test('past deadline is overdue', () {
      expect(inDays(-1), DeadlineUrgency.overdue);
      expect(inDays(-10), DeadlineUrgency.overdue);
    });

    test('today and tomorrow are imminent', () {
      expect(inDays(0), DeadlineUrgency.imminent);
      expect(inDays(1), DeadlineUrgency.imminent);
    });

    test('2 to 3 days out is approaching', () {
      expect(inDays(2), DeadlineUrgency.approaching);
      expect(inDays(3), DeadlineUrgency.approaching);
    });

    test('4 or more days out is none', () {
      expect(inDays(4), DeadlineUrgency.none);
      expect(inDays(30), DeadlineUrgency.none);
    });

    test('ignores time of day on the deadline', () {
      expect(
        DeadlineUrgency.of(DateTime(2026, 11, 8, 23, 59), today),
        DeadlineUrgency.imminent,
      );
    });
  });
}
