import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';

class TaskReorderUtils {
  static bool inSameGroup(Task a, Task b, SettingsState settings) {
    if (a.priority == Priority.urgent || b.priority == Priority.urgent) {
      return a.priority == Priority.urgent && b.priority == Priority.urgent;
    }

    if (settings.prioritizeOverdue && a.isOverdue != b.isOverdue) return false;

    if (settings.prioritizeDeadlines) {
      if (a.deadline == null && b.deadline != null) return false;
      if (a.deadline != null && b.deadline == null) return false;
      if (a.deadline != null && b.deadline != null && a.deadline != b.deadline) return false;
    }
    return true;
  }

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

    final taskOldIndex = sameGroupTasks.indexWhere((t) => t.id == draggedTask.id);

    int targetCount = 0;
    for (int i = 0; i < newIndex && i < nodes.length; i++) {
      final n = nodes[i];
      if (n is TaskNode && inSameGroup(n.task, draggedTask, settings)) {
        targetCount++;
      }
    }

    return LexoRankUtils.computeReorderSortOrder(
      sameGroupTasks,
      taskOldIndex,
      targetCount,
      (t) => t.sortOrder,
    );
  }

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

    final selectedSameGroupTasks = sameGroupTasks
        .where((t) => selectedTaskIds.contains(t.id))
        .toList();

    if (selectedSameGroupTasks.isEmpty) return null;

    final remaining = List<Task>.from(sameGroupTasks)
      ..removeWhere((t) => selectedTaskIds.contains(t.id));

    int targetCount = 0;
    for (int i = 0; i < newIndex && i < nodes.length; i++) {
      final n = nodes[i];
      if (n is TaskNode &&
          inSameGroup(n.task, draggedTask, settings) &&
          !selectedTaskIds.contains(n.task.id)) {
        targetCount++;
      }
    }

    final String? prev = targetCount == 0 ? null : remaining[targetCount - 1].sortOrder;
    final String? next = targetCount >= remaining.length ? null : remaining[targetCount].sortOrder;

    final Map<String, String> newSortOrders = {};
    String? currentPrev = prev;

    for (final task in selectedSameGroupTasks) {
      final newSortOrder = LexoRankUtils.generateBetween(currentPrev, next);
      newSortOrders[task.id] = newSortOrder;
      currentPrev = newSortOrder;
    }

    return newSortOrders;
  }
}
