import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_completion_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

extension TaskCompletionActions on TaskNotifier {
  Future<void> updateTaskStatus(
    Task task,
    TaskStatus status, {
    String? newSortOrder,
    String? newPlanSortOrder,
  }) async {
    final oldTask = await repo.getById(task.id) ?? task;
    final cmd = TaskCompletionService.buildStatusUpdateCommand(
      repo: repo,
      task: oldTask,
      status: status,
      newSortOrder: newSortOrder,
      newPlanSortOrder: newPlanSortOrder,
    );
    await executeCommand(cmd);
    if (status.isDone) await _promptParent(task);
  }

  Future<void> startTask(Task task) => executeCommand(
    TaskCompletionService.buildStartCommand(repo: repo, task: task),
  );

  Future<SubtaskCompletionConflict?> checkSubtaskConflict(Task task) =>
      subtaskService.checkSubtaskConflict(task);

  Future<void> completeTask(Task task) async {
    await executeCommand(
      TaskCompletionService.buildCompleteCommand(repo: repo, task: task),
    );
    await _promptParent(task);
  }

  Future<void> _promptParent(Task task) =>
      parentCompletionPrompt.checkAfterCompleting(task);

  Future<SubtaskCompletionConflict?> toggleComplete(
    Task task, {
    bool useTimer = false,
  }) async {
    final timerNotifier = taskTimer;
    if (timerNotifier.isTaskPending(task.id)) {
      timerNotifier.cancelPending(task.id);
      return null;
    }

    Future<SubtaskCompletionConflict?> completeTaskWithPossibleTimer(
      Task task,
    ) async {
      final conflict = await checkSubtaskConflict(task);
      if (conflict != null) return conflict;
      if (useTimer) {
        timerNotifier.startPending(
          task.id,
          settings.taskCompletionDelay,
          () => completeTask(task),
        );
      } else {
        await completeTask(task);
      }
      return null;
    }

    switch (task.status) {
      case TaskStatus.todo:
        await startTask(task);
        return null;
      case TaskStatus.inProgress when settings.reviewState:
        await updateTaskStatus(task, TaskStatus.review);
        return null;
      case TaskStatus.inProgress:
      case TaskStatus.review:
        return await completeTaskWithPossibleTimer(task);
      case TaskStatus.done:
        await updateTaskStatus(task, TaskStatus.todo);
        return null;
    }
  }

  Future<void> completeParentWithCascade(SubtaskCompletionConflict conflict) =>
      executeCommand(
        TaskCompletionService.buildCompleteParentCascadeCommand(
          repo: repo,
          conflict: conflict,
        ),
      );

  Future<void> completeParentOnly(Task parentTask) => completeTask(parentTask);
}
