import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_slot.dart';

class TaskReorderEngine {
  /// Resolves the urgent section end index in [nodes].
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

  /// Checks if two tasks belong to the same reorder group according to [settings] and view mode.
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
      return !(a.isUrgent || b.isUrgent) || (a.isUrgent && b.isUrgent);
    } else if (a.parentId != b.parentId) {
      return false;
    }
    if (a.isUrgent || b.isUrgent) return a.isUrgent && b.isUrgent;
    if (settings.prioritizeOverdue && a.isOverdue != b.isOverdue) return false;
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
      int firstChild = -1;
      int lastChild = -1;
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i].task?.parentId == parentId) {
          if (firstChild == -1) firstChild = i;
          lastChild = i;
        }
      }
      if (firstChild == -1) {
        final parentIdx = nodes.indexWhere((n) => n.task?.id == parentId);
        targetIndex = parentIdx + 1;
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
      final urgentEnd = getUrgentSectionEndIndex(nodes);
      final minSlot = draggedTask.isUrgent ? 0 : urgentEnd;
      final maxSlot = draggedTask.isUrgent ? urgentEnd : nodes.length;

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
            final midpoint = parentIdx + (groupEnd - parentIdx) / 2.0;
            clamped = clamped <= midpoint ? parentIdx : groupEnd;
            clamped = clamped.clamp(minSlot, maxSlot);
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

    final isUnchanged =
        currentIndex >= 0 &&
        (targetIndex == currentIndex || targetIndex == currentIndex + 1);

    return TaskReorderSlot(
      index: targetIndex,
      isValid: true,
      isUnchanged: isUnchanged,
    );
  }

  static bool isPositionInGroup({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
    required SettingsState settings,
    bool isPlanView = false,
  }) {
    int first = -1;
    int last = -1;
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
    return rank.isNotEmpty ? rank : '~';
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

    final urgentEnd = getUrgentSectionEndIndex(nodes);
    final isMulti =
        selectedTaskIds != null &&
        selectedTaskIds.length > 1 &&
        selectedTaskIds.contains(draggedTask.id);
    final excludeIds = isMulti ? selectedTaskIds : {draggedTask.id};

    final section = draggedTask.isUrgent
        ? nodes.sublist(0, urgentEnd)
        : nodes.sublist(urgentEnd);

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

    final start = draggedTask.isUrgent ? 0 : urgentEnd;
    final targetCount = nodes
        .sublist(start, slot.index.clamp(start, nodes.length))
        .map((n) => n.task)
        .whereType<Task>()
        .where((t) => !excludeIds.contains(t.id) && matches(t))
        .length;

    final remaining = sameGroupTasks
        .where((t) => !excludeIds.contains(t.id))
        .toList();

    if (sameGroupTasks.isEmpty || remaining.isEmpty) {
      if (!isMulti) return {draggedTask.id: LexoRank.defaultRank};
    }

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

    if (!isMulti) {
      final newRank = LexoRank.generateBetween(prev, next);
      return {draggedTask.id: newRank};
    }

    final selected = sameGroupTasks
        .where((t) => selectedTaskIds.contains(t.id))
        .toList();
    if (selected.isEmpty) return null;

    final newSortOrders = <String, String>{};
    String? currentPrev = prev;
    for (final task in selected) {
      final rank = LexoRank.generateBetween(currentPrev, next);
      newSortOrders[task.id] = rank;
      currentPrev = rank;
    }
    return newSortOrders;
  }
}
