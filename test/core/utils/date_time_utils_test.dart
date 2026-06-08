import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';

void main() {
  group('core', () {
    test('isEndOfWorkWeek should return true for Friday, Saturday, Sunday', () {
      final friday = DateTime(2026, 5, 29); // Friday
      final saturday = DateTime(2026, 5, 30); // Saturday
      final sunday = DateTime(2026, 5, 31); // Sunday
      final monday = DateTime(2026, 6, 1); // Monday

      expect(isEndOfWorkWeek(friday), isTrue);
      expect(isEndOfWorkWeek(saturday), isTrue);
      expect(isEndOfWorkWeek(sunday), isTrue);
      expect(isEndOfWorkWeek(monday), isFalse);
    });

    test('DateTimeExtension next should return the correct subsequent weekday', () {
      final monday = DateTime(2026, 6, 1); // Monday
      
      // Next Monday should be exactly 7 days later
      expect(monday.next(DateTime.monday).isSameDay(DateTime(2026, 6, 8)), isTrue);
      
      // Next Tuesday should be 1 day later
      expect(monday.next(DateTime.tuesday).isSameDay(DateTime(2026, 6, 2)), isTrue);
    });

    test('DateTimeExtension startOfWeek should return correct starting date', () {
      final wednesday = DateTime(2026, 6, 3);
      
      // If Monday is the first day of the week
      final startMonday = wednesday.startOfWeek(DateTime.monday);
      expect(startMonday.isSameDay(DateTime(2026, 6, 1)), isTrue);
      
      // If Sunday is the first day of the week
      final startSunday = wednesday.startOfWeek(DateTime.sunday);
      expect(startSunday.isSameDay(DateTime(2026, 5, 31)), isTrue);
    });

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
      
      expect(midMonth.startOfMonth().isSameDay(DateTime(2026, 6, 1)), isTrue);
      expect(midMonth.endOfMonth().isSameDay(DateTime(2026, 6, 30)), isTrue);
    });

    test('isBetween range checks', () {
      final start = DateTime(2026, 6, 1);
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
  });
}
