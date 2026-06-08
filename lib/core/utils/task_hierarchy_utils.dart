import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

class TaskHierarchyUtils {
  static List<TaskHierarchyNode> buildHierarchy(List<Task> categoryTasks, {Map<String, Task>? allTasks}) {
    final seenIds = <String>{};
    final tasks = categoryTasks.where((t) => seenIds.add(t.id)).toList();
    final taskMap = {for (final t in tasks) t.id: t};

    // Build parent→children relationships for internal tasks
    final childrenOf = <String, List<String>>{};
    for (final task in tasks) {
      final parentId = task.blockedById;
      if (parentId != null && taskMap.containsKey(parentId)) {
        childrenOf.putIfAbsent(parentId, () => []).add(task.id);
      }
    }

    final externalBlockerChildren = <String, List<String>>{};
    final externalBlockerTitles = <String, String>{};

    for (final task in tasks) {
      final parentId = task.blockedById;
      if (parentId == null || taskMap.containsKey(parentId)) {
        continue;
      }

      // Check if it's an external uncompleted blocker
      if (allTasks != null && allTasks.containsKey(parentId)) {
        final blocker = allTasks[parentId]!;
        if (!blocker.isCompleted) {
          externalBlockerChildren.putIfAbsent(blocker.id, () => []).add(task.id);
          externalBlockerTitles[blocker.id] = blocker.title;
        }
      }
    }

    // Flatten via DFS with Urgency Inheritance
    final result = <TaskHierarchyNode>[];
    final emitted = <String>{};

    void emit(String taskId, int depth) {
      if (!emitted.add(taskId)) return;
      final task = taskMap[taskId];
      if (task == null) return;

      result.add(TaskNode(task, depth));
      final children = childrenOf[taskId];
      if (children != null) {
        for (final childId in children) {
          emit(childId, depth + 1);
        }
      }
    }

    void emitExternalBlocker(String blockerId) {
      final indicatorId = 'indicator_$blockerId';
      if (!emitted.add(indicatorId)) return;

      result.add(
        BlockerIndicatorNode(
          blockerId: blockerId,
          blockerTitle: externalBlockerTitles[blockerId] ?? '',
          blockedTaskId: externalBlockerChildren[blockerId]!.first,
          depth: 0,
        ),
      );

      for (final childId in externalBlockerChildren[blockerId]!) {
        emit(childId, 1);
      }
    }

    String? findRootId(String id, Set<String> visited) {
      if (!visited.add(id)) return null;
      final task = taskMap[id];
      if (task == null) return null;

      final parentId = task.blockedById;
      if (parentId == null) return id;

      if (taskMap.containsKey(parentId)) {
        return findRootId(parentId, visited);
      }

      if (allTasks != null && allTasks.containsKey(parentId)) {
        final blocker = allTasks[parentId]!;
        if (!blocker.isCompleted) {
          return 'indicator_$parentId';
        }
      }

      return id;
    }

    for (final task in tasks) {
      final rootId = findRootId(task.id, {});
      if (rootId == null) {
        // Cycle detected: emit task as root to prevent it from disappearing
        emit(task.id, 0);
      } else if (rootId.startsWith('indicator_')) {
        emitExternalBlocker(rootId.replaceFirst('indicator_', ''));
      } else {
        emit(rootId, 0);
      }
    }

    return result;
  }
}
