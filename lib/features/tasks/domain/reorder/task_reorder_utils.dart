import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/data/models/task_position_info.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/task_prefs.dart';

class TaskReorderUtils {
  /// Get position info for a task in a list of tasks.
  /// If task is not found, returns [TaskPositionInfo.notFound].
  /// It considers task grouping based on [settings] (urgency, overdue, deadlines).
  static TaskPositionInfo getTaskPosition({
    required Task task,
    required List<Task> tasks,
    TaskPrefs? settings,
  }) {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return const TaskPositionInfo.notFound();
    bool inGroup(Task t) => settings != null
        ? TaskReorderEngine.inSameGroup(t, task, settings)
        : (t.parentId == task.parentId && t.isUrgent == task.isUrgent);
    final group = tasks.where(inGroup).toList();
    final gIdx = group.indexWhere((t) => t.id == task.id);
    return TaskPositionInfo(
      indexInList: idx,
      indexInGroup: gIdx,
      isFirstInGroup: gIdx == 0,
      isLastInGroup: gIdx == group.length - 1,
      isFirstInList: idx == 0,
      isLastInList: idx == tasks.length - 1,
    );
  }

  /// Checks whether moving a task from [currentIndex] to [targetIndex] results in no change to its position.
  static bool isPositionUnchanged({
    required int currentIndex,
    required int targetIndex,
  }) =>
      currentIndex >= 0 &&
      (targetIndex == currentIndex || targetIndex == currentIndex + 1);

  /// Checks whether moving [draggedTask] to [targetIndex] in [nodes] results in no change to its position.
  static bool isPositionUnchangedInNodes({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
  }) => isPositionUnchanged(
    currentIndex: nodes.indexWhere((n) => n.task?.id == draggedTask.id),
    targetIndex: targetIndex,
  );

  /// Calculate the new sort order for a single task when moved to a new position in a group.
  /// Returns the new sort order for the task, or null if no change is needed.
  static String? handleReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required TaskPrefs settings,
    bool isPlanView = false,
  }) {
    final slot = TaskReorderEngine.resolveSlot(
      nodes: nodes,
      draggedTask: draggedTask,
      rawIndex: newIndex,
      settings: settings,
      isPlanView: isPlanView,
    );
    final ranks = TaskReorderEngine.computeRanks(
      nodes: nodes,
      draggedTask: draggedTask,
      slot: slot,
      settings: settings,
      isPlanView: isPlanView,
    );
    return ranks?[draggedTask.id];
  }

  /// Calculate new sort orders for multiple tasks being moved together as a group.
  /// Returns a map of task IDs to their new sort orders.
  static Map<String, String>? handleMultiReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required Set<String> selectedTaskIds,
    required TaskPrefs settings,
    bool isPlanView = false,
  }) {
    if (!selectedTaskIds.contains(draggedTask.id)) return null;

    final selectedTasks = nodes
        .map((n) => n.task)
        .whereType<Task>()
        .where((t) => selectedTaskIds.contains(t.id));
    for (final task in selectedTasks) {
      if (!TaskReorderEngine.inSameGroup(
        task,
        draggedTask,
        settings,
        isPlanView: isPlanView,
        nodes: nodes,
      )) {
        return null;
      }
    }

    final slot = TaskReorderEngine.resolveSlot(
      nodes: nodes,
      draggedTask: draggedTask,
      rawIndex: newIndex,
      settings: settings,
      isPlanView: isPlanView,
    );
    return TaskReorderEngine.computeRanks(
      nodes: nodes,
      draggedTask: draggedTask,
      slot: slot,
      selectedTaskIds: selectedTaskIds,
      settings: settings,
      isPlanView: isPlanView,
    );
  }
}
