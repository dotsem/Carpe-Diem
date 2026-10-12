import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task_position_info.dart';

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
  }) {
    if (isPlanView && nodes != null) {
      final aTop =
          a.parentId == null || !nodes.any((n) => n.task?.id == a.parentId);
      final bTop =
          b.parentId == null || !nodes.any((n) => n.task?.id == b.parentId);
      if ((!aTop || !bTop) && a.parentId != b.parentId) return false;
      // In plan view only urgency partitions; deadline/overdue don't restrict reordering.
      return !(a.isUrgent || b.isUrgent) || (a.isUrgent && b.isUrgent);
    } else if (a.parentId != b.parentId) {
      return false;
    }
    if (a.isUrgent || b.isUrgent) return a.isUrgent && b.isUrgent;
    if (settings.prioritizeOverdue && a.isOverdue != b.isOverdue) return false;
    return !settings.prioritizeDeadlines || a.deadline == b.deadline;
  }

  /// Returns the effective sort rank of the task at [index] in [remaining].
  /// Returns null if [index] is out of bounds.
  static String? getEffectiveRank(
    List<Task> remaining,
    int index, {
    bool isPlanView = false,
  }) {
    if (index < 0 || index >= remaining.length) return null;
    final task = remaining[index];
    final plan = task.planSortOrder;
    final rank = isPlanView && plan != null && plan.isNotEmpty
        ? plan
        : task.sortOrder;
    return rank.isNotEmpty ? rank : '~';
  }

  /// Find the boundary index in [nodes] where the urgent section ends.
  /// All nodes before this index are effectively urgent.
  static int getUrgentSectionEndIndex(List<TaskHierarchyNode> nodes) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isRoot = node is ParentContainerNode
          ? node.depth == 0
          : (node is TaskNode && node.depth == 0 && !node.isBundledUnderParent);
      if (isRoot) {
        final isUrgent = node is ParentContainerNode
            ? (node.task.isUrgent || node.hasUrgentChild)
            : (node.task?.isUrgent ?? false);
        if (!isUrgent) return i;
      }
    }
    return nodes.length;
  }

  static int _effectiveIndex(int newIndex, bool isUrgent, int urgentEnd) {
    if (!isUrgent && newIndex < urgentEnd) return urgentEnd;
    if (isUrgent && newIndex > urgentEnd) return urgentEnd;
    return newIndex;
  }

  static ({List<Task> sameGroupTasks, List<Task> remaining, int targetCount})
  _getReorderContext({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int effectiveIndex,
    required int urgentSectionEnd,
    required SettingsState settings,
    required bool isPlanView,
    required Set<String> excludeIds,
  }) {
    final section = draggedTask.isUrgent
        ? nodes.sublist(0, urgentSectionEnd)
        : nodes.sublist(urgentSectionEnd);
    bool matches(Task t) => inSameGroup(
      t,
      draggedTask,
      settings,
      isPlanView: isPlanView,
      nodes: nodes,
    );
    final sameGroupTasks = section
        .map((n) => n.task)
        .whereType<Task>()
        .where(matches)
        .toList();
    final start = draggedTask.isUrgent ? 0 : urgentSectionEnd;
    final targetCount = nodes
        .sublist(start, effectiveIndex.clamp(start, nodes.length))
        .map((n) => n.task)
        .whereType<Task>()
        .where((t) => !excludeIds.contains(t.id) && matches(t))
        .length;
    final remaining = sameGroupTasks
        .where((t) => !excludeIds.contains(t.id))
        .toList();
    return (
      sameGroupTasks: sameGroupTasks,
      remaining: remaining,
      targetCount: targetCount,
    );
  }

  static ({int effectiveIndex, int urgentSectionEnd})? _validatedTarget(
    List<TaskHierarchyNode> nodes,
    Task task,
    int newIndex,
  ) {
    final end = getUrgentSectionEndIndex(nodes);
    final idx = _effectiveIndex(newIndex, task.isUrgent, end);
    if (isPositionUnchangedInNodes(
      draggedTask: task,
      targetIndex: idx,
      nodes: nodes,
    )) {
      return null;
    }
    return (effectiveIndex: idx, urgentSectionEnd: end);
  }

  /// Calculate the new sort order for a single task when moved to a new position in a group.
  /// Returns the new sort order for the task, or null if no change is needed.
  static String? handleReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required SettingsState settings,
    bool isPlanView = false,
  }) {
    final target = _validatedTarget(nodes, draggedTask, newIndex);
    if (target == null) return null;

    final (:sameGroupTasks, :remaining, :targetCount) = _getReorderContext(
      nodes: nodes,
      draggedTask: draggedTask,
      effectiveIndex: target.effectiveIndex,
      urgentSectionEnd: target.urgentSectionEnd,
      settings: settings,
      isPlanView: isPlanView,
      excludeIds: {draggedTask.id},
    );

    if (sameGroupTasks.isEmpty || remaining.isEmpty) return null;

    final prevRank = getEffectiveRank(
      remaining,
      targetCount - 1,
      isPlanView: isPlanView,
    );
    final nextRank = getEffectiveRank(
      remaining,
      targetCount,
      isPlanView: isPlanView,
    );

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
    bool isPlanView = false,
  }) {
    if (!selectedTaskIds.contains(draggedTask.id)) return null;

    final target = _validatedTarget(nodes, draggedTask, newIndex);
    if (target == null) return null;

    final (:sameGroupTasks, :remaining, :targetCount) = _getReorderContext(
      nodes: nodes,
      draggedTask: draggedTask,
      effectiveIndex: target.effectiveIndex,
      urgentSectionEnd: target.urgentSectionEnd,
      settings: settings,
      isPlanView: isPlanView,
      excludeIds: selectedTaskIds,
    );

    final selected = sameGroupTasks
        .where((t) => selectedTaskIds.contains(t.id))
        .toList();
    if (selected.isEmpty) return null;

    final prev = getEffectiveRank(
      remaining,
      targetCount - 1,
      isPlanView: isPlanView,
    );
    final next = getEffectiveRank(
      remaining,
      targetCount,
      isPlanView: isPlanView,
    );

    final newSortOrders = <String, String>{};
    String? currentPrev = prev;
    for (final task in selected) {
      final rank = LexoRankUtils.generateBetween(currentPrev, next);
      newSortOrders[task.id] = rank;
      currentPrev = rank;
    }
    return newSortOrders;
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
    final rank = LexoRankUtils.generateBetween(
      toTop ? null : edgeRank,
      toTop ? edgeRank : null,
    );
    provider.reorderTask(task, rank, isPlanOrder: isPlanView);
  }
}
