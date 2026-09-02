import 'dart:async';

import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_completion_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_crud_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_scheduling_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'actions/task_bulk_actions.dart';
export 'actions/task_schedule_actions.dart';

class TaskNotifier extends Notifier<TaskState> {
  late final ITaskRepository repo;

  TaskState get tasksState => state;

  @override
  TaskState build() {
    repo = ref.watch(taskRepositoryProvider);
    ref.listen<UndoRedoState>(undoRedoProvider, (prev, next) {
      if (prev != null && prev.isProcessing && !next.isProcessing) {
        if (next.lastOperationType == UndoRedoOperationType.undo ||
            next.lastOperationType == UndoRedoOperationType.redo) {
          refreshAll();
        }
      }
    });
    unawaited(
      TaskSchedulingService.autoScheduleDeadlines(
        repo: repo,
        today: DateTime.now(),
      ),
    );
    return TaskState(currentDate: DateTime.now().normalize);
  }

  Future<void> executeCommand(Command cmd) async {
    await ref.read(undoRedoProvider.notifier).execute(cmd);
    await refreshAll();
  }

  Future<void> loadTasksForDate(DateTime date, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    final normalized = date.normalize;
    state = state.copyWith(currentDate: normalized);
    final s = ref.read(settingsProvider);
    final tasks = await repo.getByDate(
      normalized,
      prioritizeDeadlines: s.prioritizeDeadlines,
      prioritizeOverdue: s.prioritizeOverdue,
    );
    final overdue = await repo.getOverdue(normalized);
    state = state.copyWith(
      tasks: tasks,
      overdueTasks: overdue,
      isLoading: false,
    );
  }

  Future<void> loadUnscheduledTasks({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    final s = ref.read(settingsProvider);
    final unscheduled = await repo.getUnscheduled(
      prioritizeDeadlines: s.prioritizeDeadlines,
      prioritizeOverdue: s.prioritizeOverdue,
    );
    state = state.copyWith(unscheduledTasks: unscheduled, isLoading: false);
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? scheduledDate,
    String? projectId,
    bool isUrgent = false,
    DateTime? deadline,
    String? blockedById,
    String? parentId,
    TaskPlacement placement = TaskPlacement.bottom,
    List<String> labelIds = const [],
    List<String> tagIds = const [],
  }) async {
    final s = ref.read(settingsProvider);
    final task = await TaskCrudService.buildNewTask(
      repo: repo,
      settings: s,
      title: title,
      description: description,
      scheduledDate: scheduledDate,
      projectId: projectId,
      isUrgent: isUrgent,
      deadline: deadline,
      blockedById: blockedById,
      parentId: parentId,
      placement: placement,
      labelIds: labelIds,
      tagIds: tagIds,
    );
    final cmd = await TaskCrudService.buildCreateWithPropagationCommand(
      repo: repo,
      task: task,
      inheritParentDeadline: s.inheritParentDeadline,
    );
    await executeCommand(cmd);
  }

  Future<void> updateTask(Task task, {TaskPlacement? placement}) async {
    final oldTask = await repo.getById(task.id);
    if (oldTask == null) return;
    final s = ref.read(settingsProvider);
    final updated = await TaskCrudService.resolveUpdatedTask(
      repo: repo,
      settings: s,
      task: task,
      placement: placement,
    );
    final cmd = await TaskCrudService.buildUpdateWithPropagationCommand(
      repo: repo,
      previous: oldTask,
      next: updated,
      inheritParentDeadline: s.inheritParentDeadline,
    );
    await executeCommand(cmd);
  }

  Future<void> deleteTask(Task task, {bool deleteSubtasks = true}) async {
    final cmd = await TaskCrudService.buildDeleteCommand(
      repo: repo,
      task: task,
      deleteSubtasks: deleteSubtasks,
    );
    await executeCommand(cmd);
  }

  Future<void> reorderTask(Task task, String newSortOrder) async {
    final updated = task.copyWith(sortOrder: newSortOrder);
    state = TaskReorderService.applyOptimisticTask(
      state: state,
      task: updated,
      settings: ref.read(settingsProvider),
    );
    final cmd = TaskReorderService.buildReorderCommand(
      repo: repo,
      previous: task,
      next: updated,
    );
    await ref.read(undoRedoProvider.notifier).execute(cmd);
  }

  Future<void> bulkReorderTasks(Map<String, String> updates) async {
    if (updates.isEmpty) return;
    state = TaskReorderService.applyBulkOptimisticReorder(
      state: state,
      updates: updates,
      settings: ref.read(settingsProvider),
    );
    final cmd = await TaskReorderService.buildBulkReorderCommand(
      repo: repo,
      updates: updates,
    );
    if (cmd != null) await ref.read(undoRedoProvider.notifier).execute(cmd);
  }

  Future<void> updateTaskStatus(
    Task task,
    TaskStatus status, {
    String? newSortOrder,
  }) async {
    final oldTask = await repo.getById(task.id) ?? task;
    final cmd = TaskCompletionService.buildStatusUpdateCommand(
      repo: repo,
      task: oldTask,
      status: status,
      newSortOrder: newSortOrder,
    );
    await executeCommand(cmd);
  }

  Future<void> startTask(Task task) async {
    final cmd = TaskCompletionService.buildStartCommand(repo: repo, task: task);
    await executeCommand(cmd);
  }

  Future<SubtaskCompletionConflict?> checkSubtaskConflict(Task task) =>
      SubtaskService.checkSubtaskConflict(repo: repo, task: task);

  Future<void> completeTask(Task task) async {
    final cmd = TaskCompletionService.buildCompleteCommand(
      repo: repo,
      task: task,
    );
    await executeCommand(cmd);
    if (task.parentId != null) {
      await SubtaskService.checkAndAutoCompleteParent(
        repo: repo,
        parentId: task.parentId!,
        onCompleteParent: completeTask,
      );
    }
  }

  Future<SubtaskCompletionConflict?> toggleComplete(
    Task task, {
    bool useTimer = false,
  }) async {
    final timerNotifier = ref.read(taskTimerProvider.notifier);
    if (timerNotifier.isTaskPending(task.id)) {
      timerNotifier.cancelPending(task.id);
      return null;
    }
    switch (task.status) {
      case TaskStatus.todo:
        await startTask(task);
        return null;
      case TaskStatus.inProgress:
        final conflict = await checkSubtaskConflict(task);
        if (conflict != null) return conflict;
        if (useTimer) {
          final s = ref.read(settingsProvider);
          timerNotifier.startPending(
            task.id,
            s.taskCompletionDelay,
            () => completeTask(task),
          );
        } else {
          await completeTask(task);
        }
        return null;
      case TaskStatus.done:
        await updateTaskStatus(task, TaskStatus.todo);
        return null;
    }
  }

  Future<void> completeParentWithCascade(
    SubtaskCompletionConflict conflict,
  ) async {
    final cmd = TaskCompletionService.buildCompleteParentCascadeCommand(
      repo: repo,
      conflict: conflict,
    );
    await executeCommand(cmd);
  }

  Future<void> completeParentOnly(Task parentTask) => completeTask(parentTask);

  List<Task> getAllSubtasks(String parentId) => SubtaskService.getAllSubtasks(
    parentId: parentId,
    allTasks: [
      ...state.tasks,
      ...state.overdueTasks,
      ...state.unscheduledTasks,
    ],
  );

  Future<List<Task>> getTasksForProject(String projectId) => repo.getByProject(
    projectId,
    prioritizeDeadlines: ref.read(settingsProvider).prioritizeDeadlines,
  );

  Future<void> refreshTasks() => refreshAll();

  Future<void> refreshAll() async {
    await loadTasksForDate(state.currentDate, silent: true);
    await loadUnscheduledTasks(silent: true);
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() {
  return TaskNotifier();
});
