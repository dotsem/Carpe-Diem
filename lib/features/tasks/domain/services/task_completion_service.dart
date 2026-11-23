import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

class TaskCompletionService {
  static Command buildCompleteCommand({
    required ITaskRepository repo,
    required Task task,
  }) {
    final updated = task
        .withStatus(TaskStatus.done)
        .copyWith(
          scheduledDate: task.scheduledDate ?? DateTime.now().normalize,
        );
    return UpdateCommand(
      repo: repo,
      previous: task,
      next: updated,
      displayName: task.title,
    );
  }

  static Command buildStartCommand({
    required ITaskRepository repo,
    required Task task,
  }) {
    final updated = task
        .withStatus(TaskStatus.inProgress)
        .copyWith(
          scheduledDate: task.scheduledDate ?? DateTime.now().normalize,
        );
    return UpdateCommand(
      repo: repo,
      previous: task,
      next: updated,
      displayName: task.title,
    );
  }

  static Command buildStatusUpdateCommand({
    required ITaskRepository repo,
    required Task task,
    required TaskStatus status,
    String? newSortOrder,
    String? newPlanSortOrder,
  }) {
    final updated = task
        .withStatus(status)
        .copyWith(
          sortOrder: newSortOrder ?? task.sortOrder,
          scheduledDate: status == TaskStatus.todo
              ? task.scheduledDate
              : (task.scheduledDate ?? DateTime.now().normalize),
          planSortOrder: newPlanSortOrder ?? task.planSortOrder,
        );
    return UpdateCommand(
      repo: repo,
      previous: task,
      next: updated,
      displayName: task.title,
    );
  }

  static CompoundCommand buildCompleteParentCascadeCommand({
    required ITaskRepository repo,
    required SubtaskCompletionConflict conflict,
  }) {
    final now = DateTime.now();
    final commands = <Command>[
      for (final subtask in conflict.incompleteSubtasks)
        UpdateCommand(
          repo: repo,
          previous: subtask,
          next: subtask
              .withStatus(TaskStatus.done, at: now)
              .copyWith(scheduledDate: subtask.scheduledDate ?? now.normalize),
          displayName: subtask.title,
        ),
      UpdateCommand(
        repo: repo,
        previous: conflict.parentTask,
        next: conflict.parentTask
            .withStatus(TaskStatus.done, at: now)
            .copyWith(
              scheduledDate: conflict.parentTask.scheduledDate ?? now.normalize,
            ),
        displayName: conflict.parentTask.title,
      ),
    ];
    return CompoundCommand(
      commands,
      'Complete "${conflict.parentTask.title}" and ${conflict.incompleteSubtasks.length} subtasks',
    );
  }
}
