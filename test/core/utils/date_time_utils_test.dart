import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('core', () {
    test('isEndOfWorkWeek should return true for Friday, Saturday, Sunday', () {
      final friday = DateTime(2026, 5, 29); // Friday
      final saturday = DateTime(2026, 5, 30); // Saturday
      final sunday = DateTime(2026, 5, 31); // Sunday
      final monday = DateTime(2026, 6); // Monday

      expect(isEndOfWorkWeek(friday), isTrue);
      expect(isEndOfWorkWeek(saturday), isTrue);
      expect(isEndOfWorkWeek(sunday), isTrue);
      expect(isEndOfWorkWeek(monday), isFalse);
    });

    test(
      'DateTimeExtension next should return the correct subsequent weekday',
      () {
        final monday = DateTime(2026, 6); // Monday

        // Next Monday should be exactly 7 days later
        expect(
          monday.next(DateTime.monday).isSameDay(DateTime(2026, 6, 8)),
          isTrue,
        );

        // Next Tuesday should be 1 day later
        expect(
          monday.next(DateTime.tuesday).isSameDay(DateTime(2026, 6, 2)),
          isTrue,
        );
      },
    );

    test(
      'DateTimeExtension startOfWeek should return correct starting date',
      () {
        final wednesday = DateTime(2026, 6, 3);

        // If Monday is the first day of the week
        final startMonday = wednesday.startOfWeek(DateTime.monday);
        expect(startMonday.isSameDay(DateTime(2026, 6)), isTrue);

        // If Sunday is the first day of the week
        final startSunday = wednesday.startOfWeek(DateTime.sunday);
        expect(startSunday.isSameDay(DateTime(2026, 5, 31)), isTrue);
      },
    );

    test('isSameDay / isBeforeDay / isAfterDay validations', () {
      final dateA = DateTime(2026, 6, 1, 10, 30);
      final dateB = DateTime(2026, 6, 1, 22, 15);
      final dateC = DateTime(2026, 6, 2);

      expect(dateA.isSameDay(dateB), isTrue);
      expect(dateA.isSameDay(dateC), isFalse);

      expect(dateA.isBeforeDay(dateC), isTrue);
      expect(dateC.isAfterDay(dateA), isTrue);

      expect(dateA.isBeforeDay(dateB), isFalse); // Same day is not before
    });

    test('startOfMonth / endOfMonth boundaries', () {
      final midMonth = DateTime(2026, 6, 15);

      expect(midMonth.startOfMonth().isSameDay(DateTime(2026, 6)), isTrue);
      expect(midMonth.endOfMonth().isSameDay(DateTime(2026, 6, 30)), isTrue);
    });

    test('isBetween range checks', () {
      final start = DateTime(2026, 6);
      final end = DateTime(2026, 6, 10);

      final inside = DateTime(2026, 6, 5);
      final outsideBefore = DateTime(2026, 5, 31);
      final outsideAfter = DateTime(2026, 6, 11);

      expect(inside.isBetween(start, end), isTrue);
      expect(start.isBetween(start, end), isTrue);
      expect(end.isBetween(start, end), isTrue);
      expect(outsideBefore.isBetween(start, end), isFalse);
      expect(outsideAfter.isBetween(start, end), isFalse);
    });

    test(
      'null-safe day comparisons, today and tomorrow checks, and fractional days',
      () {
        final now = DateTime.now();
        expect(todayIsEndOfWorkWeek(), isA<bool>());
        expect(now.startOfNextWeek(DateTime.monday), now.next(DateTime.monday));
        expect(DateTime(2026, 6).isStartOfWeek(DateTime.monday), isTrue);
        expect(now.isSameDay(null), isFalse);
        expect(now.isBeforeDay(null), isFalse);
        expect(now.isAfterDay(null), isFalse);
        expect(now.isToday, isTrue);
        expect(now.add(const Duration(days: 1)).isTomorrow, isTrue);
        expect(now.daysFromToday, 0);
        expect(
          DateTime(
            2026,
            1,
            1,
            12,
          ).fractionalDaysUntil(DateTime(2026, 1, 2, 18)),
          1.25,
        );
        expect(DateTime(2026, 1, 2).fractionalDaysUntil(DateTime(2026)), 0);
        expect(DateTime(2026, 1, 2, 12).normalize, DateTime(2026, 1, 2));
      },
    );

    group('daysUntil', () {
      test('counts calendar days across spring-forward dst', () {
        expect(DateTime(2026, 3, 28).daysUntil(DateTime(2026, 3, 30)), 2);
      });

      test('counts calendar days across fall-back dst', () {
        expect(DateTime(2026, 10, 24).daysUntil(DateTime(2026, 10, 26)), 2);
      });

      test('returns 0 for same day and negative for past', () {
        expect(DateTime(2026, 5).daysUntil(DateTime(2026, 5)), 0);
        expect(DateTime(2026, 5, 3).daysUntil(DateTime(2026, 5)), -2);
      });

      test('ignores time of day', () {
        expect(DateTime(2026, 1, 1, 23).daysUntil(DateTime(2026, 1, 2, 1)), 1);
      });
    });
  });
}
