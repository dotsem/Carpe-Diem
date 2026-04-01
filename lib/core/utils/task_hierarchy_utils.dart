import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_hierarchy_node.dart';

class TaskHierarchyUtils {
  static List<TaskHierarchyNode> buildHierarchy(List<Task> categoryTasks, {Map<String, Task>? allTasks}) {
    final idSet = categoryTasks.map((t) => t.id).toSet();
    final childrenMap = <String, List<Task>>{};
    final roots = <TaskHierarchyNode>[];

    for (final task in categoryTasks) {
      if (task.blockedById != null && idSet.contains(task.blockedById)) {
        childrenMap.putIfAbsent(task.blockedById!, () => []).add(task);
      } else if (task.blockedById != null && allTasks != null && allTasks.containsKey(task.blockedById)) {
        final blocker = allTasks[task.blockedById]!;
        if (!blocker.isCompleted) {
          roots.add(
            BlockerIndicatorNode(blockerId: blocker.id, blockerTitle: blocker.title, blockedTaskId: task.id, depth: 0),
          );
          childrenMap.putIfAbsent(blocker.id, () => []).add(task);
        } else {
          roots.add(TaskNode(task, 0));
        }
      } else {
        roots.add(TaskNode(task, 0));
      }
    }

    final result = <TaskHierarchyNode>[];
    void addNode(TaskHierarchyNode node) {
      result.add(node);

      String? id;
      if (node is TaskNode) {
        id = node.task.id;
      } else if (node is BlockerIndicatorNode) {
        id = node.blockerId;
      }

      if (id != null) {
        final children = childrenMap[id];
        if (children != null) {
          for (final child in children) {
            addNode(TaskNode(child, node.depth + 1));
          }
        }
      }
    }

    for (final root in roots) {
      // Avoid adding the same task multiple times if it was handled as a child elsewhere
      if (root is TaskNode && result.any((n) => n is TaskNode && n.task.id == root.task.id)) {
        continue;
      }
      addNode(root);
    }
    return result;
  }
}
