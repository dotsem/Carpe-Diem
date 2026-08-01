import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

class TaskPositionInfo {
  final int indexInList;
  final int indexInGroup;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isFirstInList;
  final bool isLastInList;

  const TaskPositionInfo({
    required this.indexInList,
    required this.indexInGroup,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.isFirstInList,
    required this.isLastInList,
  });

  const TaskPositionInfo.notFound()
    : indexInList = -1,
      indexInGroup = -1,
      isFirstInGroup = false,
      isLastInGroup = false,
      isFirstInList = false,
      isLastInList = false;
}

class TaskReorderUtils {
  /// Get position info for a task in a list of tasks.
  /// If task is not found, returns [TaskPositionInfo.notFound].
  /// It considers task grouping based on [settings] (urgency, overdue, deadlines).
  static TaskPositionInfo getTaskPosition({required Task task, required List<Task> tasks, SettingsState? settings}) {
    final indexInList = tasks.indexWhere((t) => t.id == task.id);
    if (indexInList == -1) return const TaskPositionInfo.notFound();

    final sameGroup = tasks
        .where((t) => settings != null ? inSameGroup(t, task, settings) : t.isUrgent == task.isUrgent)
        .toList();

    final indexInGroup = sameGroup.indexWhere((t) => t.id == task.id);

    return TaskPositionInfo(
      indexInList: indexInList,
      indexInGroup: indexInGroup,
      isFirstInGroup: indexInGroup == 0,
      isLastInGroup: indexInGroup == sameGroup.length - 1,
      isFirstInList: indexInList == 0,
      isLastInList: indexInList == tasks.length - 1,
    );
  }

  /// Check if two tasks are in the same group based on [settings] (urgency, overdue, deadlines).
  static bool inSameGroup(Task a, Task b, SettingsState settings) {
    if (a.isUrgent || b.isUrgent) {
      return a.isUrgent && b.isUrgent;
    }

    if (settings.prioritizeOverdue && a.isOverdue != b.isOverdue) return false;

    if (settings.prioritizeDeadlines) {
      if (a.deadline == null && b.deadline != null) return false;
      if (a.deadline != null && b.deadline == null) return false;
      if (a.deadline != null && b.deadline != null && a.deadline != b.deadline) {
        return false;
      }
    }
    return true;
  }

  /// Find the effective rank of a task at a given index in a list.
  /// Considers existing sort orders and generates intermediate ranks if needed.
  /// Returns the new sort order for the task, or null if no change is needed.
  static String? _getEffectiveRank(List<Task> remaining, int index) {
    if (index < 0 || index >= remaining.length) return null;
    final task = remaining[index];
    if (task.sortOrder.isNotEmpty) return task.sortOrder;

    String? prevRank;
    int prevIndex = -1;
    for (int k = index - 1; k >= 0; k--) {
      if (remaining[k].sortOrder.isNotEmpty) {
        prevRank = remaining[k].sortOrder;
        prevIndex = k;
        break;
      }
    }

    String? nextRank;
    for (int k = index + 1; k < remaining.length; k++) {
      if (remaining[k].sortOrder.isNotEmpty) {
        nextRank = remaining[k].sortOrder;
        break;
      }
    }

    String? current = prevRank;
    final steps = index - prevIndex;
    for (int s = 0; s < steps; s++) {
      current = LexoRankUtils.generateBetween(current, nextRank);
    }
    return current;
  }

  /// Calculate the new sort order for a single task when moved to a new position in a group.
  /// Returns the new sort order for the task, or null if no change is needed.
  static String? handleReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required SettingsState settings,
  }) {
    final sameGroupTasks = nodes
        .whereType<TaskNode>()
        .map((n) => n.task)
        .where((t) => inSameGroup(t, draggedTask, settings))
        .toList();

    if (sameGroupTasks.isEmpty) return null;

    final taskOldIndex = sameGroupTasks.indexWhere((t) => t.id == draggedTask.id);

    int targetCount = 0;
    for (int i = 0; i < newIndex && i < nodes.length; i++) {
      final n = nodes[i];
      if (n is TaskNode && inSameGroup(n.task, draggedTask, settings)) {
        targetCount++;
      }
    }

    final remaining = List<Task>.from(sameGroupTasks);
    if (taskOldIndex >= 0 && taskOldIndex < remaining.length) {
      remaining.removeAt(taskOldIndex);
    }

    int adjustedIndex = (taskOldIndex >= 0 && taskOldIndex < targetCount) ? targetCount - 1 : targetCount;

    final prevRank = _getEffectiveRank(remaining, adjustedIndex - 1);
    final nextRank = _getEffectiveRank(remaining, adjustedIndex);

    return LexoRankUtils.generateBetween(prevRank, nextRank);
  }

  /// Calculate new sort orders for multiple tasks being moved together as a group.
  /// Returns a map of task IDs to their new sort orders.
  static Map<String, String>? handleMultiReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required Set<String> selectedTaskIds,
    required SettingsState settings,
  }) {
    if (!selectedTaskIds.contains(draggedTask.id)) return null;

    final sameGroupTasks = nodes
        .whereType<TaskNode>()
        .map((n) => n.task)
        .where((t) => inSameGroup(t, draggedTask, settings))
        .toList();

    final selectedSameGroupTasks = sameGroupTasks.where((t) => selectedTaskIds.contains(t.id)).toList();

    if (selectedSameGroupTasks.isEmpty) return null;

    final remaining = List<Task>.from(sameGroupTasks)..removeWhere((t) => selectedTaskIds.contains(t.id));

    int targetCount = 0;
    for (int i = 0; i < newIndex && i < nodes.length; i++) {
      final n = nodes[i];
      if (n is TaskNode && inSameGroup(n.task, draggedTask, settings) && !selectedTaskIds.contains(n.task.id)) {
        targetCount++;
      }
    }

    final String? prev = _getEffectiveRank(remaining, targetCount - 1);
    final String? next = _getEffectiveRank(remaining, targetCount);

    final Map<String, String> newSortOrders = {};
    String? currentPrev = prev;

    for (final task in selectedSameGroupTasks) {
      final newSortOrder = LexoRankUtils.generateBetween(currentPrev, next);
      newSortOrders[task.id] = newSortOrder;
      currentPrev = newSortOrder;
    }

    return newSortOrders;
  }

  static void moveToTop(TaskNotifier provider, Task task, List<Task> tasks, SettingsState settings) {
    final sameGroupTasks = tasks.where((t) => inSameGroup(t, task, settings)).toList();

    final taskOldIndex = sameGroupTasks.indexWhere((t) => t.id == task.id);

    if (taskOldIndex == 0) return;

    final topRank = _getEffectiveRank(sameGroupTasks, 0);
    final newSortOrder = LexoRankUtils.generateBetween(null, topRank);
    provider.updateTask(task.copyWith(sortOrder: newSortOrder));
  }

  static void moveToBottom(TaskNotifier provider, Task task, List<Task> tasks, SettingsState settings) {
    final sameGroupTasks = tasks.where((t) => inSameGroup(t, task, settings)).toList();

    final taskOldIndex = sameGroupTasks.indexWhere((t) => t.id == task.id);

    if (taskOldIndex == sameGroupTasks.length - 1) return;

    final bottomRank = _getEffectiveRank(sameGroupTasks, sameGroupTasks.length - 1);
    final newSortOrder = LexoRankUtils.generateBetween(bottomRank, null);
    provider.updateTask(task.copyWith(sortOrder: newSortOrder));
  }
}
