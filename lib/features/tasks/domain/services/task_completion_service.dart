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
    final updated = task.copyWith(
      status: TaskStatus.done,
      scheduledDate: task.scheduledDate ?? DateTime.now().normalize,
      completedAt: DateTime.now(),
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
    final updated = task.copyWith(
      status: TaskStatus.inProgress,
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
  }) {
    final updated = task.copyWith(
      status: status,
      sortOrder: newSortOrder ?? task.sortOrder,
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
          next: subtask.copyWith(
            status: TaskStatus.done,
            scheduledDate: subtask.scheduledDate ?? now.normalize,
            completedAt: now,
          ),
          displayName: subtask.title,
        ),
      UpdateCommand(
        repo: repo,
        previous: conflict.parentTask,
        next: conflict.parentTask.copyWith(
          status: TaskStatus.done,
          scheduledDate: conflict.parentTask.scheduledDate ?? now.normalize,
          completedAt: now,
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
