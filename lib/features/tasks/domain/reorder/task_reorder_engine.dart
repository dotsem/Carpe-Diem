import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_slot.dart';

class TaskReorderEngine {
  static bool _isRootNode(TaskHierarchyNode node) => node is ParentContainerNode
      ? node.depth == 0
      : (node is TaskNode && node.depth == 0 && !node.isBundledUnderParent);

  static bool _isNodeUrgent(TaskHierarchyNode node) =>
      node is ParentContainerNode
      ? (node.task.isUrgent || node.hasUrgentChild)
      : (node.task?.isUrgent ?? false);

  static bool _isNodeOverdue(TaskHierarchyNode node) =>
      node.task?.isOverdue ?? false;

  /// Resolves the urgent section end index in [nodes].
  static int getUrgentSectionEndIndex(List<TaskHierarchyNode> nodes) {
    for (int i = 0; i < nodes.length; i++) {
      if (_isRootNode(nodes[i]) && !_isNodeUrgent(nodes[i])) return i;
    }
    return nodes.length;
  }

  /// Resolves the overdue section end index in [nodes] after [urgentEnd].
  static int getOverdueSectionEndIndex(
    List<TaskHierarchyNode> nodes,
    int urgentEnd,
  ) {
    for (int i = urgentEnd; i < nodes.length; i++) {
      if (_isRootNode(nodes[i]) && !_isNodeOverdue(nodes[i])) return i;
    }
    return nodes.length;
  }

  static (int start, int end) _getSectionBounds(
    List<TaskHierarchyNode> nodes,
    Task task,
    SettingsState? settings,
  ) {
    final urgentEnd = getUrgentSectionEndIndex(nodes);
    if (task.isUrgent) return (0, urgentEnd);
    final hasOverdue = settings?.prioritizeOverdue ?? false;
    final overdueEnd = hasOverdue
        ? getOverdueSectionEndIndex(nodes, urgentEnd)
        : urgentEnd;
    return (hasOverdue && task.isOverdue)
        ? (urgentEnd, overdueEnd)
        : (overdueEnd, nodes.length);
  }

  static bool inSameGroup(
    Task a,
    Task b,
    SettingsState settings, {
    bool isPlanView = false,
    List<TaskHierarchyNode>? nodes,
  }) {
    if (a.isUrgent || b.isUrgent) return a.isUrgent && b.isUrgent;
    if (settings.prioritizeOverdue && a.isOverdue != b.isOverdue) return false;
    if (isPlanView && nodes != null) {
      bool isTop(Task t) =>
          t.parentId == null || !nodes.any((n) => n.task?.id == t.parentId);
      return (isTop(a) && isTop(b)) || a.parentId == b.parentId;
    }
    if (a.parentId != b.parentId) return false;
    return !settings.prioritizeDeadlines || a.deadline == b.deadline;
  }

  /// Phase 1: Resolves raw hovering index into a validated, clamped, and snapped slot.
  static TaskReorderSlot resolveSlot({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int rawIndex,
    SettingsState? settings,
    bool isPlanView = false,
  }) {
    if (nodes.isEmpty) {
      return const TaskReorderSlot(index: 0, isValid: true, isUnchanged: false);
    }

    final currentIndex = nodes.indexWhere((n) => n.task?.id == draggedTask.id);
    final parentId = draggedTask.parentId;
    final isParentInNodes =
        parentId != null && nodes.any((n) => n.task?.id == parentId);

    int targetIndex;

    if (parentId != null && isParentInNodes) {
      // Subtask: strictly clamped to sibling subtask range under existing parent
      int firstChild = -1, lastChild = -1;
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i].task?.parentId == parentId) {
          if (firstChild == -1) firstChild = i;
          lastChild = i;
        }
      }
      if (firstChild == -1) {
        targetIndex = nodes.indexWhere((n) => n.task?.id == parentId) + 1;
      } else {
        int endChild = lastChild + 1;
        final lastDepth = nodes[lastChild].depth;
        while (endChild < nodes.length && nodes[endChild].depth > lastDepth) {
          endChild++;
        }
        targetIndex = rawIndex.clamp(firstChild, endChild);
      }
    } else {
      // Root task (or orphan subtask)
      final (minSlot, maxSlot) = _getSectionBounds(
        nodes,
        draggedTask,
        settings,
      );
      var clamped = rawIndex.clamp(minSlot, maxSlot);

      // Auto-snap outside parent container if dropped into a subtask slot
      if (clamped < nodes.length) {
        final node = nodes[clamped];
        if ((node is TaskNode && node.isBundledUnderParent) ||
            (node.task?.parentId != null && node.depth > 0)) {
          final pId = node.task?.parentId;
          int parentIdx = -1;
          int groupEnd = clamped + 1;
          for (int i = 0; i < nodes.length; i++) {
            if (nodes[i].task?.id == pId) parentIdx = i;
            if (nodes[i].task?.parentId == pId) groupEnd = i + 1;
          }
          if (parentIdx != -1) {
            final mid = parentIdx + (groupEnd - parentIdx) / 2.0;
            clamped = (clamped <= mid ? parentIdx : groupEnd).clamp(
              minSlot,
              maxSlot,
            );
          }
        }
      }
      targetIndex = clamped;
    }

    if (settings != null &&
        !isPositionInGroup(
          draggedTask: draggedTask,
          targetIndex: targetIndex,
          nodes: nodes,
          settings: settings,
          isPlanView: isPlanView,
        )) {
      return const TaskReorderSlot.invalid();
    }

    return TaskReorderSlot(
      index: targetIndex,
      isValid: true,
      isUnchanged:
          currentIndex >= 0 &&
          (targetIndex == currentIndex || targetIndex == currentIndex + 1),
    );
  }

  static bool isPositionInGroup({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
    required SettingsState settings,
    bool isPlanView = false,
  }) {
    int first = -1, last = -1;
    for (int i = 0; i < nodes.length; i++) {
      final t = nodes[i].task;
      if (t != null &&
          inSameGroup(
            t,
            draggedTask,
            settings,
            isPlanView: isPlanView,
            nodes: nodes,
          )) {
        if (first == -1) first = i;
        last = i;
      }
    }
    if (first == -1) return true;
    int effectiveLast = last;
    final parentId = draggedTask.parentId;
    final isParentInNodes =
        parentId != null && nodes.any((n) => n.task?.id == parentId);
    if (!isParentInNodes && last >= 0) {
      final parentDepth = nodes[last].depth;
      while (effectiveLast + 1 < nodes.length &&
          nodes[effectiveLast + 1].depth > parentDepth) {
        effectiveLast++;
      }
    }
    return targetIndex >= first && targetIndex <= effectiveLast + 1;
  }

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
    return (rank.isNotEmpty && rank != '~') ? rank : null;
  }

  /// Phase 2: Computes updated LexoRank strings for the dragged task or selected tasks.
  static Map<String, String>? computeRanks({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required TaskReorderSlot slot,
    Set<String>? selectedTaskIds,
    SettingsState? settings,
    bool isPlanView = false,
  }) {
    if (!slot.isValid || slot.isUnchanged) return null;

    final (start, end) = _getSectionBounds(nodes, draggedTask, settings);
    final isMulti =
        selectedTaskIds != null &&
        selectedTaskIds.length > 1 &&
        selectedTaskIds.contains(draggedTask.id);
    final excludeIds = isMulti ? selectedTaskIds : {draggedTask.id};

    final section = nodes.sublist(start, end);

    bool matches(Task t) => settings != null
        ? inSameGroup(
            t,
            draggedTask,
            settings,
            isPlanView: isPlanView,
            nodes: nodes,
          )
        : (t.parentId == draggedTask.parentId &&
              t.isUrgent == draggedTask.isUrgent);

    final sameGroupTasks = section
        .map((n) => n.task)
        .whereType<Task>()
        .where(matches)
        .toList();
    final targetCount = nodes
        .sublist(start, slot.index.clamp(start, nodes.length))
        .map((n) => n.task)
        .whereType<Task>()
        .where((t) => !excludeIds.contains(t.id) && matches(t))
        .length;

    final remaining = sameGroupTasks
        .where((t) => !excludeIds.contains(t.id))
        .toList();
    if (sameGroupTasks.isEmpty && !isMulti) {
      return {draggedTask.id: LexoRank.defaultRank};
    }
    if (remaining.isEmpty && !isMulti) {
      final cur = isPlanView
          ? draggedTask.planSortOrder
          : draggedTask.sortOrder;
      return (cur != null && cur.isNotEmpty && cur != '~')
          ? null
          : {draggedTask.id: LexoRank.defaultRank};
    }

    String? prev;
    for (int i = targetCount - 1; i >= 0 && prev == null; i--) {
      prev = getEffectiveRank(remaining, i, isPlanView: isPlanView);
    }

    String? next;
    for (int i = targetCount; i < remaining.length && next == null; i++) {
      next = getEffectiveRank(remaining, i, isPlanView: isPlanView);
    }
    if (!isMulti) {
      return {draggedTask.id: LexoRank.generateBetween(prev, next)};
    }

    final selected = sameGroupTasks
        .where((t) => selectedTaskIds.contains(t.id))
        .toList();
    if (selected.isEmpty) return null;

    final newSortOrders = <String, String>{};
    String? currentPrev = prev;
    for (final task in selected) {
      final rank = LexoRank.generateBetween(currentPrev, next);
      newSortOrders[task.id] = currentPrev = rank;
    }
    return newSortOrders;
  }
}
