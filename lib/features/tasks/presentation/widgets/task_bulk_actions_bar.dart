import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/bulk_tasks_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bulk planning bar for screens that list tasks and select several of them.
///
/// [selectedTaskIds] and [tasks] are owned by the screen. [onClearSelection]
/// also resets the shift-select anchor, [onActionCompleted] only clears the ids.
class TaskBulkActionsBar extends ConsumerWidget {
  final List<String> selectedTaskIds;
  final List<Task> tasks;
  final VoidCallback onClearSelection;
  final VoidCallback onActionCompleted;
  final VoidCallback onScheduleToday;
  final VoidCallback onScheduleTomorrow;

  const TaskBulkActionsBar({
    required this.selectedTaskIds,
    required this.tasks,
    required this.onClearSelection,
    required this.onActionCompleted,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    super.key,
  });

  Task? _selectedTask() =>
      tasks.where((t) => t.id == selectedTaskIds.first).firstOrNull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alreadyScheduled = selectedTaskIds
        .map((id) => tasks.where((t) => t.id == id).firstOrNull)
        .whereType<Task>()
        .every((task) => task.scheduledDate != null);

    return BulkPlanningBar(
      selectedTaskIds: selectedTaskIds,
      onClearSelection: onClearSelection,
      disableScheduling: alreadyScheduled,
      onScheduleToday: onScheduleToday,
      onScheduleTomorrow: onScheduleTomorrow,
      onBulkEdit: () {
        if (selectedTaskIds.length == 1) {
          final task = _selectedTask();
          if (task != null) context.openRightSidebar(EditTaskPanel(task.id));
        } else {
          showBulkEditTasksDialog(
            context: context,
            ref: ref,
            selectedTaskIds: selectedTaskIds,
            onCompleted: onActionCompleted,
          );
        }
      },
      onGroupTasks: () {
        showGroupTasksDialog(
          context: context,
          ref: ref,
          selectedTaskIds: selectedTaskIds,
          onCompleted: onActionCompleted,
        );
      },
      onBulkDelete: () {
        if (selectedTaskIds.length != 1) {
          showBulkDeleteTasksConfirmDialog(
            context: context,
            ref: ref,
            selectedTaskIds: selectedTaskIds,
            onCompleted: onActionCompleted,
          );
          return;
        }
        final task = _selectedTask();
        if (task == null) return;
        final subtasks = ref
            .read(taskProvider.notifier)
            .getAllSubtasks(task.id);
        final message = subtasks.isEmpty
            ? 'Are you sure you want to delete this task?'
            : "Are you sure you want to delete this task and its ${subtasks.length} subtask${subtasks.length > 1 ? 's' : ''}?";

        showDialog<void>(
          context: context,
          builder: (ctx) => DeleteDialog(
            title: 'Delete Task',
            message: message,
            onConfirm: () {
              ref.read(taskProvider.notifier).deleteTask(task);
              onActionCompleted();
            },
          ),
        );
      },
    );
  }
}
