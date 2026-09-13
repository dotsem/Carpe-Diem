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

    bool hasUrgentSubtask(String taskId) {
      if (allTasks != null) {
        return allTasks.values.any(
          (t) => t.parentId == taskId && t.isUrgent && !t.isCompleted,
        );
      }
      final children = childrenOf[taskId];
      if (children == null) return false;
      return children.any((id) {
        final t = taskMap[id];
        return t != null && t.isUrgent && !t.isCompleted;
      });
    }

    bool isEffectivelyUrgent(Task task) {
      if (task.isUrgent && !task.isCompleted) return true;
      return hasUrgentSubtask(task.id);
    }

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

        final hasUrgent = hasUrgentSubtask(taskId);
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

    for (final task in tasks) {
      final isSubtaskInView =
          task.parentId != null && taskMap.containsKey(task.parentId);
      if (!isSubtaskInView && isEffectivelyUrgent(task)) {
        emit(task.id, 0);
      }
    }

    for (final task in tasks) {
      final isSubtaskInView =
          task.parentId != null && taskMap.containsKey(task.parentId);
      if (!isSubtaskInView) {
        emit(task.id, 0);
      }
    }

    for (final task in tasks) {
      if (!emitted.contains(task.id)) {
        emit(task.id, 0);
      }
    }

    return result;
  }
}
