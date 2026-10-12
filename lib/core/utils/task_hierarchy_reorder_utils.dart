import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

class TaskHierarchyReorderUtils {
  static bool isPositionValidInNodes({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
    SettingsState? settings,
    bool isPlanView = false,
  }) {
    if (targetIndex < 0 || targetIndex > nodes.length) return false;

    if (settings != null &&
        !isPositionInGroup(
          draggedTask: draggedTask,
          targetIndex: targetIndex,
          nodes: nodes,
          settings: settings,
          isPlanView: isPlanView,
        )) {
      return false;
    }

    final parentId = draggedTask.parentId;
    final isParentInNodes =
        parentId != null && nodes.any((n) => n.task?.id == parentId);

    if (parentId == null || !isParentInNodes) {
      if (targetIndex == nodes.length) return true;
      final node = nodes[targetIndex];
      if (node is TaskNode && node.isBundledUnderParent) return false;
      if (node.task?.parentId != null && node.depth > 0) return false;
      return true;
    }

    final childIndices = <int>[];
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].task?.parentId == parentId) {
        childIndices.add(i);
      }
    }

    if (childIndices.isEmpty) return false;

    if (targetIndex < nodes.length &&
        nodes[targetIndex].task?.parentId == parentId) {
      return true;
    }

    final lastChildIndex = childIndices.last;
    int endIndex = lastChildIndex + 1;
    final lastChildDepth = nodes[lastChildIndex].depth;
    while (endIndex < nodes.length && nodes[endIndex].depth > lastChildDepth) {
      endIndex++;
    }

    return targetIndex == endIndex;
  }

  static bool isLastChildInGroup({
    required Task task,
    required int index,
    required List<TaskHierarchyNode> nodes,
  }) {
    if (task.parentId == null) return false;
    final isParentInNodes = nodes.any((n) => n.task?.id == task.parentId);
    if (!isParentInNodes) return false;
    if (index < 0 || index >= nodes.length) return false;
    if (nodes[index].task?.parentId != task.parentId) return false;

    int lastChildIndex = -1;
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].task?.parentId == task.parentId) {
        lastChildIndex = i;
      }
    }

    return index == lastChildIndex;
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
          TaskReorderUtils.inSameGroup(
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
    return targetIndex >= first && targetIndex <= last + 1;
  }
}
