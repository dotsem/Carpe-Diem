import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskHistoryNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> cleanupHistory({
    required Future<void> Function() onCleanup,
  }) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final settings = ref.read(settingsProvider);
    final days = settings.historyRetention;
    if (days > 0) {
      final deletedCount = await taskRepo.cleanupHistory(days);
      if (deletedCount > 0) {
        await onCleanup();
      }
    }
  }

  Future<List<Task>> getCompletedTasks(
    DateTime start,
    DateTime end, {
    int? limit,
    int? offset,
    TaskFilter? filter,
  }) async {
    final historyRepo = ref.read(historyRepositoryProvider);
    return historyRepo.getCompletedInRange(
      start,
      end,
      limit: limit,
      offset: offset,
      filter: filter,
    );
  }

  Future<DateTime> getFirstTaskDate() async {
    final historyRepo = ref.read(historyRepositoryProvider);
    final firstCompleted = await historyRepo.getFirstCompletedDate();
    if (firstCompleted != null) return firstCompleted;
    return DateTime.now();
  }

  Future<HistoryOverview> getHistoryOverview(
    DateTime start,
    DateTime end, {
    TaskFilter? filter,
  }) async {
    final historyRepo = ref.read(historyRepositoryProvider);
    return historyRepo.getHistoryOverview(start, end, filter: filter);
  }
}

final taskHistoryProvider = NotifierProvider<TaskHistoryNotifier, void>(() {
  return TaskHistoryNotifier();
});
