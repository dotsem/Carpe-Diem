import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

class TaskHierarchyUtils {
  static List<TaskHierarchyNode> buildHierarchy(
    List<Task> categoryTasks, {
    Map<String, Task>? allTasks,
    Set<String>? collapsedParentIds,
  }) {
    final seenIds = <String>{};
    final tasks = categoryTasks.where((t) => seenIds.add(t.id)).toList();
    final taskMap = {for (final t in tasks) t.id: t};

    final childrenOf = <String, List<String>>{};
    for (final task in tasks) {
      final parentId = task.parentId ?? task.blockedById;
      if (parentId != null && taskMap.containsKey(parentId)) {
        childrenOf.putIfAbsent(parentId, () => []).add(task.id);
      }
    }

    final externalBlockerChildren = <String, List<String>>{};
    final externalBlockerTitles = <String, String>{};

    for (final task in tasks) {
      // Only check external blocker if task doesn't have an in-map parentId/blockedById
      final effectiveParent = task.parentId ?? task.blockedById;
      if (effectiveParent != null && taskMap.containsKey(effectiveParent)) {
        continue;
      }

      final blockerId = task.blockedById;
      if (blockerId != null &&
          !taskMap.containsKey(blockerId) &&
          allTasks != null &&
          allTasks.containsKey(blockerId)) {
        final blocker = allTasks[blockerId]!;
        if (!blocker.isCompleted) {
          externalBlockerChildren
              .putIfAbsent(blocker.id, () => [])
              .add(task.id);
          externalBlockerTitles[blocker.id] = blocker.title;
        }
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
      result.add(
        TaskNode(task, depth, isBundledUnderParent: isBundledUnderParent),
      );
      if (collapsedParentIds != null && collapsedParentIds.contains(taskId)) {
        return;
      }
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

      final effectiveParent = task.parentId ?? task.blockedById;
      if (effectiveParent == null) return id;

      if (taskMap.containsKey(effectiveParent)) {
        return findRootId(effectiveParent, visited);
      }

      if (task.blockedById != null &&
          allTasks != null &&
          allTasks.containsKey(task.blockedById)) {
        final blocker = allTasks[task.blockedById]!;
        if (!blocker.isCompleted) {
          return 'indicator_${task.blockedById}';
        }
      }

      return id;
    }

    for (final task in tasks) {
      final rootId = findRootId(task.id, {});
      if (rootId == null) {
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
