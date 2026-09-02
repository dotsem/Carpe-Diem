import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskSelectionUtils {
  /// Returns `true` if all subtasks are selected, `false` if none are selected,
  /// and `null` (indeterminate) if some are selected.
  /// If there are no subtasks, returns whether the parentId itself is selected.
  static bool? getParentSelectionState({
    required String parentId,
    required List<Task> subtasks,
    required Set<String> selectedTaskIds,
  }) {
    if (subtasks.isEmpty) {
      return selectedTaskIds.contains(parentId);
    }
    final selectedCount = subtasks
        .where((t) => selectedTaskIds.contains(t.id))
        .length;
    if (selectedCount == 0) {
      return selectedTaskIds.contains(parentId) ? null : false;
    }
    if (selectedCount == subtasks.length) {
      return true;
    }
    return null;
  }

  /// Toggles selection for a parent task or subtask and updates parent-child state.
  static Set<String> toggleSelection({
    required Task task,
    required List<Task> allTasks,
    required Set<String> currentSelectedIds,
  }) {
    final subtasks = allTasks.where((t) => t.parentId == task.id).toList();

    // Parent task with subtasks
    if (subtasks.isNotEmpty) {
      final currentState = getParentSelectionState(
        parentId: task.id,
        subtasks: subtasks,
        selectedTaskIds: currentSelectedIds,
      );

      final newSet = Set<String>.from(currentSelectedIds);
      if (currentState == true) {
        newSet.remove(task.id);
        for (final subtask in subtasks) {
          newSet.remove(subtask.id);
        }
      } else {
        newSet.add(task.id);
        for (final subtask in subtasks) {
          newSet.add(subtask.id);
        }
      }
      return newSet;
    }

    // Subtask with a parent
    if (task.parentId != null) {
      final newSet = Set<String>.from(currentSelectedIds);
      final isSelected = newSet.contains(task.id);

      if (isSelected) {
        newSet.remove(task.id);
        newSet.remove(task.parentId!);
      } else {
        newSet.add(task.id);
        final parentSubtasks = allTasks
            .where((t) => t.parentId == task.parentId)
            .toList();
        final allSelected = parentSubtasks.every((t) => newSet.contains(t.id));
        if (allSelected) {
          newSet.add(task.parentId!);
        }
      }
      return newSet;
    }

    // Standalone task
    final newSet = Set<String>.from(currentSelectedIds);
    if (newSet.contains(task.id)) {
      newSet.remove(task.id);
    } else {
      newSet.add(task.id);
    }
    return newSet;
  }
}
