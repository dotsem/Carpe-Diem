import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task_position_info.dart';

export 'package:carpe_diem/features/tasks/data/models/task_position_info.dart';

class TaskReorderUtils {
  /// Get position info for a task in a list of tasks.
  /// If task is not found, returns [TaskPositionInfo.notFound].
  /// It considers task grouping based on [settings] (urgency, overdue, deadlines).
  static TaskPositionInfo getTaskPosition({
    required Task task,
    required List<Task> tasks,
    SettingsState? settings,
  }) {
    final indexInList = tasks.indexWhere((t) => t.id == task.id);
    if (indexInList == -1) return const TaskPositionInfo.notFound();

    final sameGroup = tasks
        .where(
          (t) => settings != null
              ? inSameGroup(t, task, settings)
              : (t.parentId == task.parentId && t.isUrgent == task.isUrgent),
        )
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

  /// Checks whether moving a task from [currentIndex] to [targetIndex] results in no change to its position.
  static bool isPositionUnchanged({
    required int currentIndex,
    required int targetIndex,
  }) {
    if (currentIndex < 0) return false;
    return targetIndex == currentIndex || targetIndex == currentIndex + 1;
  }

  /// Checks whether moving [draggedTask] to [targetIndex] in [nodes] results in no change to its position.
  static bool isPositionUnchangedInNodes({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
  }) {
    final currentIndex = nodes.indexWhere((n) => n.task?.id == draggedTask.id);
    return isPositionUnchanged(
      currentIndex: currentIndex,
      targetIndex: targetIndex,
    );
  }

  static bool inSameGroup(Task a, Task b, SettingsState settings) {
    if (a.parentId != b.parentId) return false;

    if (a.isUrgent || b.isUrgent) {
      return a.isUrgent && b.isUrgent;
    }

    if (settings.prioritizeOverdue && a.isOverdue != b.isOverdue) return false;

    if (settings.prioritizeDeadlines && a.deadline != b.deadline) return false;

    return true;
  }

  /// Find the effective rank of a task at a given index in a list.
  /// Considers existing sort orders and generates intermediate ranks if needed.
  /// Returns the new sort order for the task, or null if no change is needed.
  static String? getEffectiveRank(List<Task> remaining, int index) {
    if (index < 0 || index >= remaining.length) return null;
    final task = remaining[index];
    // Empty sortOrder is stored as '~' in SQL — match that here so ranks are consistent.
    if (task.sortOrder.isNotEmpty) return task.sortOrder;
    return '~';
  }

  /// Find the boundary index in [nodes] where the urgent section ends.
  /// All nodes before this index are effectively urgent.
  static int getUrgentSectionEndIndex(List<TaskHierarchyNode> nodes) {
    int urgentEnd = 0;
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isRoot = switch (node) {
        ParentContainerNode p => p.depth == 0,
        TaskNode t => t.depth == 0 && !t.isBundledUnderParent,
        _ => true,
      };
      if (isRoot) {
        final isUrgent = switch (node) {
          ParentContainerNode p => p.task.isUrgent || p.hasUrgentChild,
          TaskNode t => t.task.isUrgent,
          _ => node.task?.isUrgent ?? false,
        };
        if (!isUrgent) return i;
      }
      urgentEnd = i + 1;
    }
    return urgentEnd;
  }

  /// Calculate the new sort order for a single task when moved to a new position in a group.
  /// Returns the new sort order for the task, or null if no change is needed.
  static String? handleReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required SettingsState settings,
  }) {
    final urgentSectionEnd = getUrgentSectionEndIndex(nodes);
    final isDraggedUrgent = draggedTask.isUrgent;
    final effectiveIndex = !isDraggedUrgent && newIndex < urgentSectionEnd
        ? urgentSectionEnd
        : (isDraggedUrgent && newIndex > urgentSectionEnd
              ? urgentSectionEnd
              : newIndex);

    if (isPositionUnchangedInNodes(
      draggedTask: draggedTask,
      targetIndex: effectiveIndex,
      nodes: nodes,
    )) {
      return null;
    }

    final sectionNodes = !isDraggedUrgent
        ? nodes.sublist(urgentSectionEnd)
        : nodes.sublist(0, urgentSectionEnd);

    final sameGroupTasks = sectionNodes
        .map((n) => n.task)
        .whereType<Task>()
        .where((t) => inSameGroup(t, draggedTask, settings))
        .toList();

    if (sameGroupTasks.isEmpty) return null;

    final taskOldIndex = sameGroupTasks.indexWhere(
      (t) => t.id == draggedTask.id,
    );

    int targetCount = 0;
    final startIndex = !isDraggedUrgent ? urgentSectionEnd : 0;
    for (int i = startIndex; i < effectiveIndex && i < nodes.length; i++) {
      final n = nodes[i];
      if (n.task != null && inSameGroup(n.task!, draggedTask, settings)) {
        targetCount++;
      }
    }

    final remaining = List<Task>.from(sameGroupTasks);
    if (taskOldIndex >= 0 && taskOldIndex < remaining.length) {
      remaining.removeAt(taskOldIndex);
    }

    int adjustedIndex = (taskOldIndex >= 0 && taskOldIndex < targetCount)
        ? targetCount - 1
        : targetCount;

    final prevRank = getEffectiveRank(remaining, adjustedIndex - 1);
    final nextRank = getEffectiveRank(remaining, adjustedIndex);

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

    final urgentSectionEnd = getUrgentSectionEndIndex(nodes);
    final isDraggedUrgent = draggedTask.isUrgent;
    final effectiveIndex = !isDraggedUrgent && newIndex < urgentSectionEnd
        ? urgentSectionEnd
        : (isDraggedUrgent && newIndex > urgentSectionEnd
              ? urgentSectionEnd
              : newIndex);

    if (isPositionUnchangedInNodes(
      draggedTask: draggedTask,
      targetIndex: effectiveIndex,
      nodes: nodes,
    )) {
      return null;
    }

    final sectionNodes = !isDraggedUrgent
        ? nodes.sublist(urgentSectionEnd)
        : nodes.sublist(0, urgentSectionEnd);

    final sameGroupTasks = sectionNodes
        .map((n) => n.task)
        .whereType<Task>()
        .where((t) => inSameGroup(t, draggedTask, settings))
        .toList();

    final selectedSameGroupTasks = sameGroupTasks
        .where((t) => selectedTaskIds.contains(t.id))
        .toList();

    if (selectedSameGroupTasks.isEmpty) return null;

    final remaining = List<Task>.from(sameGroupTasks)
      ..removeWhere((t) => selectedTaskIds.contains(t.id));

    int targetCount = 0;
    final startIndex = !isDraggedUrgent ? urgentSectionEnd : 0;
    for (int i = startIndex; i < effectiveIndex && i < nodes.length; i++) {
      final n = nodes[i];
      if (n.task != null &&
          inSameGroup(n.task!, draggedTask, settings) &&
          !selectedTaskIds.contains(n.task!.id)) {
        targetCount++;
      }
    }

    final String? prev = getEffectiveRank(remaining, targetCount - 1);
    final String? next = getEffectiveRank(remaining, targetCount);

    final Map<String, String> newSortOrders = {};
    String? currentPrev = prev;

    for (final task in selectedSameGroupTasks) {
      final newSortOrder = LexoRankUtils.generateBetween(currentPrev, next);
      newSortOrders[task.id] = newSortOrder;
      currentPrev = newSortOrder;
    }

    return newSortOrders;
  }

  static void moveToTop(
    TaskNotifier provider,
    Task task,
    List<Task> tasks,
    SettingsState settings,
  ) {
    final sameGroupTasks = tasks
        .where((t) => inSameGroup(t, task, settings))
        .toList();

    final taskOldIndex = sameGroupTasks.indexWhere((t) => t.id == task.id);

    if (taskOldIndex == 0) return;

    final topRank = getEffectiveRank(sameGroupTasks, 0);
    final newSortOrder = LexoRankUtils.generateBetween(null, topRank);
    provider.reorderTask(task, newSortOrder);
  }

  static void moveToBottom(
    TaskNotifier provider,
    Task task,
    List<Task> tasks,
    SettingsState settings,
  ) {
    final sameGroupTasks = tasks
        .where((t) => inSameGroup(t, task, settings))
        .toList();

    final taskOldIndex = sameGroupTasks.indexWhere((t) => t.id == task.id);

    if (taskOldIndex == sameGroupTasks.length - 1) return;

    final bottomRank = getEffectiveRank(
      sameGroupTasks,
      sameGroupTasks.length - 1,
    );
    final newSortOrder = LexoRankUtils.generateBetween(bottomRank, null);
    provider.reorderTask(task, newSortOrder);
  }
}
