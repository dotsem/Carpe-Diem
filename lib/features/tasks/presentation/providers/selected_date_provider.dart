import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/clock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = ref.read(clockProvider);
  return DateTime(now.year, now.month, now.day);
});

final daysRangeProvider = Provider<List<DateTime>>((ref) {
  final settings = ref.watch(settingsProvider);
  final now = ref.watch(clockProvider);
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(
    settings.maxPlanningDays + 1,
    (i) => DateTime(today.year, today.month, today.day + i),
  );
});
