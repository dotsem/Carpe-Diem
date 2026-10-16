import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';

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
  }) => TaskReorderEngine.isLastChildInGroup(
    task: task,
    index: index,
    nodes: nodes,
  );

  static bool isPositionInGroup({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
    required SettingsState settings,
    bool isPlanView = false,
  }) => TaskReorderEngine.isPositionInGroup(
    draggedTask: draggedTask,
    targetIndex: targetIndex,
    nodes: nodes,
    settings: settings,
    isPlanView: isPlanView,
  );

  static int getClampedTopIndex({
    required Task task,
    required List<TaskHierarchyNode> nodes,
    required int urgentSectionEndIndex,
  }) {
    if (task.parentId != null) {
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i].task?.parentId == task.parentId) {
          return i;
        }
      }
    }
    if (!task.isUrgent && urgentSectionEndIndex > 0) {
      return urgentSectionEndIndex;
    }
    return 0;
  }

  static int getClampedBottomIndex({
    required Task task,
    required List<TaskHierarchyNode> nodes,
    required int urgentSectionEndIndex,
  }) {
    if (task.parentId != null) {
      int lastChild = -1;
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i].task?.parentId == task.parentId) {
          lastChild = i;
        }
      }
      if (lastChild != -1) {
        int endIndex = lastChild + 1;
        final lastChildDepth = nodes[lastChild].depth;
        while (endIndex < nodes.length &&
            nodes[endIndex].depth > lastChildDepth) {
          endIndex++;
        }
        return endIndex;
      }
    }
    if (task.isUrgent && urgentSectionEndIndex < nodes.length) {
      return urgentSectionEndIndex;
    }
    return nodes.length;
  }
}
