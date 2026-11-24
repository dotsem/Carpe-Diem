import 'package:carpe_diem/core/utils/task_sort_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/task_prefs.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';

extension TaskStateReorderExtension on TaskState {
  TaskState applyOptimisticTask(
    Task task,
    TaskPrefs prefs, {
    bool isPlanOrder = false,
  }) => copyWith(
    tasks: _optimisticallyReorder(tasks, task, prefs, isPlanView: isPlanOrder),
    overdueTasks: _optimisticallyReorder(
      overdueTasks,
      task,
      prefs,
      isPlanView: isPlanOrder,
    ),
    unscheduledTasks: _optimisticallyReorder(unscheduledTasks, task, prefs),
  );

  TaskState applyBulkOptimisticReorder(
    Map<String, String> updates,
    TaskPrefs prefs, {
    bool isPlanOrder = false,
  }) => copyWith(
    tasks: applyBulkOptimisticReorderList(
      tasks,
      updates,
      prefs,
      isPlanOrder: isPlanOrder,
    ),
    overdueTasks: applyBulkOptimisticReorderList(
      overdueTasks,
      updates,
      prefs,
      isPlanOrder: isPlanOrder,
    ),
    unscheduledTasks: applyBulkOptimisticReorderList(
      unscheduledTasks,
      updates,
      prefs,
    ),
  );

  static List<Task> applyBulkOptimisticReorderList(
    List<Task> list,
    Map<String, String> updates,
    TaskPrefs prefs, {
    bool isPlanOrder = false,
  }) {
    var current = List<Task>.from(list);
    for (final entry in updates.entries) {
      final index = current.indexWhere((task) => task.id == entry.key);
      if (index == -1) continue;
      final updated = isPlanOrder
          ? current[index].copyWith(planSortOrder: entry.value)
          : current[index].copyWith(sortOrder: entry.value);
      current = _optimisticallyReorder(
        current,
        updated,
        prefs,
        isPlanView: isPlanOrder,
      );
    }
    return current;
  }
}

List<Task> _optimisticallyReorder(
  List<Task> current,
  Task updated,
  TaskPrefs prefs, {
  bool isPlanView = false,
}) {
  if (!current.any((task) => task.id == updated.id)) return current;
  final result = current
      .map((task) => task.id == updated.id ? updated : task)
      .toList();
  TaskSortUtils.sortTasks(result, prefs, isPlanView: isPlanView);
  return result;
}
