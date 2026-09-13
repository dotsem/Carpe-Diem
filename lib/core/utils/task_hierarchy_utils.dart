import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

/// Utility for constructing structured task hierarchy trees from flat task lists.
///
/// Hierarchy Rules
/// - Parent-Child Composition: Grouping is governed strictly by [Task.parentId].
///   Dependencies such as [Task.blockedById] are distinct from hierarchy and do
///   not cause nesting.
/// - Top-Level Ordering: Only true root tasks (`parentId == null`) or orphan
///   subtasks whose parent is absent from the view are emitted at depth 0.
///   Subtasks in view are emitted exclusively under their parent, so their local
///   `sortOrder` values cannot pull or push parent positions in the root list.
/// - Effective Urgency: A root task is promoted to the urgent section at the
///   top of the list if it is urgent itself or contains at least one active,
///   incomplete urgent subtask in the current view. Root tasks within each section
///   strictly preserve their own relative root sort order.
/// - Nesting Modes: If [asParentContainers] is `true`, parents with subtasks
///   in view are emitted as a [ParentContainerNode] summarizing subtask counts and
///   urgency. When `false`, they are emitted as a standard [TaskNode] with depth 0,
///   followed by indented child [TaskNode] items at depth 1+.
class TaskHierarchyUtils {
  /// Builds a flattened hierarchy of [TaskHierarchyNode] items from [categoryTasks].
  ///
  /// [categoryTasks] contains the tasks visible in the current category/list.
  /// [allTasks] is an optional broader lookup map used to calculate accurate total,
  /// completed, and urgent subtask counts when subtasks span beyond the current view.
  /// [collapsedParentIds] specifies which parent containers have their subtasks hidden.
  /// [asParentContainers] toggles between parent container cards and plain task nodes.
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
