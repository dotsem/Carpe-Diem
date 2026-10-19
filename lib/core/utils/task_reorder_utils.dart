import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task_position_info.dart';

import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';

class TaskReorderUtils {
  /// Get position info for a task in a list of tasks.
  /// If task is not found, returns [TaskPositionInfo.notFound].
  /// It considers task grouping based on [settings] (urgency, overdue, deadlines).
  static TaskPositionInfo getTaskPosition({
    required Task task,
    required List<Task> tasks,
    SettingsState? settings,
  }) {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return const TaskPositionInfo.notFound();
    bool inGroup(Task t) => settings != null
        ? inSameGroup(t, task, settings)
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

  static bool inSameGroup(
    Task a,
    Task b,
    SettingsState settings, {
    bool isPlanView = false,
    List<TaskHierarchyNode>? nodes,
  }) => TaskReorderEngine.inSameGroup(
    a,
    b,
    settings,
    isPlanView: isPlanView,
    nodes: nodes,
  );

  /// Returns the effective sort rank of the task at [index] in [remaining].
  /// Returns null if [index] is out of bounds.
  static String? getEffectiveRank(
    List<Task> remaining,
    int index, {
    bool isPlanView = false,
  }) => TaskReorderEngine.getEffectiveRank(
    remaining,
    index,
    isPlanView: isPlanView,
  );

  /// Find the boundary index in [nodes] where the urgent section ends.
  /// All nodes before this index are effectively urgent.
  static int getUrgentSectionEndIndex(List<TaskHierarchyNode> nodes) =>
      TaskReorderEngine.getUrgentSectionEndIndex(nodes);

  /// Calculate the new sort order for a single task when moved to a new position in a group.
  /// Returns the new sort order for the task, or null if no change is needed.
  static String? handleReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required SettingsState settings,
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
    required SettingsState settings,
    bool isPlanView = false,
  }) {
    if (!selectedTaskIds.contains(draggedTask.id)) return null;

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

  static void moveToTop(
    TaskNotifier provider,
    Task task,
    List<Task> tasks,
    SettingsState settings, {
    bool isPlanView = false,
  }) => _moveToEdge(provider, task, tasks, settings, isPlanView, true);

  static void moveToBottom(
    TaskNotifier provider,
    Task task,
    List<Task> tasks,
    SettingsState settings, {
    bool isPlanView = false,
  }) => _moveToEdge(provider, task, tasks, settings, isPlanView, false);

  static void _moveToEdge(
    TaskNotifier provider,
    Task task,
    List<Task> tasks,
    SettingsState settings,
    bool isPlanView,
    bool toTop,
  ) {
    final same = tasks.where((t) => inSameGroup(t, task, settings)).toList();
    if (same.isEmpty || (toTop ? same.first.id : same.last.id) == task.id) {
      return;
    }
    final edgeIdx = toTop ? 0 : same.length - 1;
    final edgeRank = getEffectiveRank(same, edgeIdx, isPlanView: isPlanView);
    final rank = LexoRank.generateBetween(
      toTop ? null : edgeRank,
      toTop ? edgeRank : null,
    );
    provider.reorderTask(task, rank, isPlanOrder: isPlanView);
  }
}
