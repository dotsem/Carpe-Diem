import 'package:carpe_diem/data/models/task.dart';

class TaskHierarchyUtils {
  static List<TaskWithDepth> buildHierarchy(List<Task> categoryTasks) {
    final idSet = categoryTasks.map((t) => t.id).toSet();
    final childrenMap = <String, List<Task>>{};
    final roots = <Task>[];

    for (final task in categoryTasks) {
      if (task.blockedById != null && idSet.contains(task.blockedById)) {
        childrenMap.putIfAbsent(task.blockedById!, () => []).add(task);
      } else {
        roots.add(task);
      }
    }

    final result = <TaskWithDepth>[];
    void addTree(Task task, int depth) {
      result.add(TaskWithDepth(task, depth));
      final children = childrenMap[task.id];
      if (children != null) {
        for (final child in children) {
          addTree(child, depth + 1);
        }
      }
    }

    for (final root in roots) {
      addTree(root, 0);
    }
    return result;
  }
}

class TaskWithDepth {
  final Task task;
  final int depth;

  const TaskWithDepth(this.task, this.depth);
}
