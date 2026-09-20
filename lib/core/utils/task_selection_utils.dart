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

  /// Selects a range of tasks between `lastSelectedTaskId` and `targetTask`
  /// using the provided `orderedIds` display sequence.
  static Set<String> selectRange({
    required Task targetTask,
    required String? lastSelectedTaskId,
    required List<String> orderedIds,
    required Set<String> currentSelectedIds,
    required List<Task> allTasks,
  }) {
    if (lastSelectedTaskId == null ||
        !orderedIds.contains(lastSelectedTaskId)) {
      return toggleSelection(
        task: targetTask,
        allTasks: allTasks,
        currentSelectedIds: currentSelectedIds,
      );
    }

    final startIndex = orderedIds.indexOf(lastSelectedTaskId);
    final endIndex = orderedIds.indexOf(targetTask.id);

    if (startIndex == -1 || endIndex == -1) {
      return toggleSelection(
        task: targetTask,
        allTasks: allTasks,
        currentSelectedIds: currentSelectedIds,
      );
    }

    final minIdx = startIndex < endIndex ? startIndex : endIndex;
    final maxIdx = startIndex < endIndex ? endIndex : startIndex;

    final rangeIds = orderedIds.sublist(minIdx, maxIdx + 1);
    final newSet = <String>{...rangeIds};

    final taskMap = {for (var t in allTasks) t.id: t};
    for (final id in rangeIds) {
      final task = taskMap[id];
      if (task != null) {
        final subtasks = allTasks.where((t) => t.parentId == task.id);
        for (final sub in subtasks) {
          newSet.add(sub.id);
        }
      }
    }

    return newSet;
  }

  /// Handles selection toggles, performing a range selection if `isShiftPressed` is true.
  static Set<String> handleSelection({
    required Task task,
    required String? lastSelectedTaskId,
    required List<String> orderedIds,
    required Set<String> currentSelectedIds,
    required List<Task> allTasks,
    required bool isShiftPressed,
  }) {
    if (isShiftPressed && lastSelectedTaskId != null) {
      return selectRange(
        targetTask: task,
        lastSelectedTaskId: lastSelectedTaskId,
        orderedIds: orderedIds,
        currentSelectedIds: currentSelectedIds,
        allTasks: allTasks,
      );
    }
    return toggleSelection(
      task: task,
      allTasks: allTasks,
      currentSelectedIds: currentSelectedIds,
    );
  }
}
