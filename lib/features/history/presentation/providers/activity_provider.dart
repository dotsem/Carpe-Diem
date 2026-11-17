import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/core/utils/history_stats_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key is the calendar year, or null for the last 12 months.
final activityProvider = FutureProvider.autoDispose.family<ActivityData, int?>((
  ref,
  year,
) async {
  // Why: survive tab switches; HistoryScreen invalidates on open and on filter or range change
  ref.keepAlive();
  final firstCompleted = await ref
      .read(historyRepositoryProvider)
      .getFirstCompletedDate();
  final window = activityWindow(
    year,
    now: DateTime.now(),
    firstCompleted: firstCompleted,
  );
  if (firstCompleted == null) {
    return ActivityData(
      dailyCounts: const {},
      start: window.start,
      end: window.end,
    );
  }

  final completions = await ref
      .read(historyInsightsRepositoryProvider)
      .getCompletionsSince(window.start);
  final days = completions
      .map((c) => c.completedAt)
      .where((d) => !d.normalize.isAfter(window.end))
      .toList();

  return ActivityData(
    dailyCounts: dailyCounts(days),
    start: window.start,
    end: window.end,
  );
});

final activityYearsProvider = FutureProvider.autoDispose<List<int>>((
  ref,
) async {
  ref.keepAlive();
  final first = await ref
      .read(historyRepositoryProvider)
      .getFirstCompletedDate();
  if (first == null) return const [];
  return [for (var y = DateTime.now().year; y >= first.year; y--) y];
});
