import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/selected_date_provider.dart';

void main() {
  group('tasks', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize to today at midnight', () {
      final selectedDate = container.read(selectedDateProvider);
      final now = DateTime.now();
      expect(selectedDate.year, equals(now.year));
      expect(selectedDate.month, equals(now.month));
      expect(selectedDate.day, equals(now.day));
      expect(selectedDate.hour, equals(0));
      expect(selectedDate.minute, equals(0));
      expect(selectedDate.second, equals(0));
      expect(selectedDate.millisecond, equals(0));
      expect(selectedDate.microsecond, equals(0));
    });

    test('should update selected date when state is changed', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      container.read(selectedDateProvider.notifier).state = tomorrow;

      final updatedDate = container.read(selectedDateProvider);
      expect(updatedDate, equals(tomorrow));
    });

    test('SelectedDateExtension normalized getter should return midnight date', () {
      final date = DateTime(2026, 6, 28, 15, 30, 45);
      final normalized = date.normalize;
      expect(normalized, equals(DateTime(2026, 6, 28)));
    });

    test('SelectedDateExtension isToday should return true for today and false for other days', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));

      expect(today.isToday, isTrue);
      expect(tomorrow.isToday, isFalse);
      expect(yesterday.isToday, isFalse);
    });

    test('SelectedDateExtension daysFromToday should calculate difference in days correctly', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final nextWeek = today.add(const Duration(days: 7));
      final yesterday = today.subtract(const Duration(days: 1));

      expect(today.daysFromToday, equals(0));
      expect(tomorrow.daysFromToday, equals(1));
      expect(nextWeek.daysFromToday, equals(7));
      expect(yesterday.daysFromToday, equals(-1));
    });
  });
}
