import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

class TaskHierarchyUtils {
  static List<TaskHierarchyNode> buildHierarchy(
    List<Task> categoryTasks, {
    Map<String, Task>? allTasks,
    Set<String>? collapsedParentIds,
    bool asParentContainers = false,
  }) {
    final seenIds = <String>{};
    final tasks = categoryTasks.where((t) => seenIds.add(t.id)).toList();
    final taskMap = {for (final t in tasks) t.id: t};

    final childrenOf = <String, List<String>>{};
    for (final task in tasks) {
      if (task.parentId != null && taskMap.containsKey(task.parentId)) {
        childrenOf.putIfAbsent(task.parentId!, () => []).add(task.id);
      }
    }

    final result = <TaskHierarchyNode>[];
    final emitted = <String>{};

    void emit(String taskId, int depth) {
      if (!emitted.add(taskId)) return;
      final task = taskMap[taskId];
      if (task == null) return;

      final isBundledUnderParent =
          task.parentId != null && taskMap.containsKey(task.parentId);
      final children = childrenOf[taskId];
      final subtasksInView =
          children?.where((id) => taskMap[id]?.parentId == taskId).toList() ??
          [];
      final hasSubtasksInView = subtasksInView.isNotEmpty;

      if (asParentContainers && hasSubtasksInView && depth == 0) {
        final allSubtasks = allTasks != null
            ? allTasks.values.where((t) => t.parentId == taskId).toList()
            : subtasksInView.map((id) => taskMap[id]!).toList();

        final hasUrgent = allSubtasks.any((t) => t.isUrgent && !t.isCompleted);
        final completedCount = allSubtasks.where((t) => t.isCompleted).length;
        final plannedCount = allSubtasks
            .where((t) => t.scheduledDate != null && !t.isCompleted)
            .length;

        result.add(
          ParentContainerNode(
            task: task,
            depth: depth,
            totalSubtasks: allSubtasks.isNotEmpty
                ? allSubtasks.length
                : subtasksInView.length,
            completedSubtasks: completedCount,
            plannedSubtasks: plannedCount,
            hasUrgentChild: hasUrgent,
            isCollapsed:
                collapsedParentIds != null &&
                collapsedParentIds.contains(taskId),
          ),
        );
      } else {
        result.add(
          TaskNode(task, depth, isBundledUnderParent: isBundledUnderParent),
        );
      }

      if (collapsedParentIds != null && collapsedParentIds.contains(taskId)) {
        return;
      }
      if (children != null) {
        for (final childId in children) {
          emit(childId, depth + 1);
        }
      }
    }

    String? findRootId(String id, Set<String> visited) {
      if (!visited.add(id)) return null;
      final task = taskMap[id];
      if (task == null) return null;

      if (task.parentId != null && taskMap.containsKey(task.parentId)) {
        return findRootId(task.parentId!, visited);
      }

      return id;
    }

    for (final task in tasks) {
      final rootId = findRootId(task.id, {});
      emit(rootId ?? task.id, 0);
    }

    return result;
  }
}
