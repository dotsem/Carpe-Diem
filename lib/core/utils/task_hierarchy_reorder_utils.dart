import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

class TaskHierarchyReorderUtils {
  static bool isPositionValidInNodes({
    required Task draggedTask,
    required int targetIndex,
    required List<TaskHierarchyNode> nodes,
  }) {
    if (targetIndex < 0 || targetIndex > nodes.length) return false;

    if (draggedTask.parentId == null) {
      if (targetIndex == nodes.length) return true;
      final node = nodes[targetIndex];
      if (node is TaskNode && node.isBundledUnderParent) return false;
      if (node.task?.parentId != null && node.depth > 0) return false;
      return true;
    }

    final parentId = draggedTask.parentId!;
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
}
