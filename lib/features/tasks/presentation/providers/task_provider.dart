import 'dart:async';

import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/common/presentation/providers/task_service_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_crud_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_scheduling_service.dart';
import 'package:carpe_diem/features/tasks/domain/task_draft.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/parent_completion_prompt_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state_reorder_extension.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskNotifier extends Notifier<TaskState> {
  late final ITaskRepository repo;
  TaskState get tasksState => state;
  SettingsState get settings => ref.read(settingsProvider);
  IProjectRepository get projectRepo => ref.read(projectRepositoryProvider);
  TaskCrudService get crudService => ref.read(taskCrudServiceProvider);
  TaskReorderService get reorderService => ref.read(taskReorderServiceProvider);
  SubtaskService get subtaskService => ref.read(subtaskServiceProvider);
  TaskSchedulingService get schedulingService =>
      ref.read(taskSchedulingServiceProvider);
  DeadlinePropagationService get deadlinePropagationService =>
      ref.read(deadlinePropagationServiceProvider);
  ParentCompletionPromptNotifier get parentCompletionPrompt =>
      ref.read(parentCompletionPromptProvider.notifier);
  TaskTimerNotifier get taskTimer => ref.read(taskTimerProvider.notifier);

  @override
  TaskState build() {
    repo = ref.watch(taskRepositoryProvider);
    ref.listen<UndoRedoState>(undoRedoProvider, (prev, next) {
      final isUndoRedo =
          next.lastOperationType == UndoRedoOperationType.undo ||
          next.lastOperationType == UndoRedoOperationType.redo;
      if (prev != null &&
          prev.isProcessing &&
          !next.isProcessing &&
          isUndoRedo) {
        refreshAll();
      }
    });
    unawaited(_init());
    return TaskState(currentDate: DateTime.now().normalize, isLoading: true);
  }

  Future<void> _init() async {
    await schedulingService.autoScheduleDeadlines(today: DateTime.now());
    if (!ref.mounted) return;
    await refreshAll();
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false);
  }

  Future<void> executeCommand(Command cmd) async {
    await ref.read(undoRedoProvider.notifier).execute(cmd);
    await refreshAll();
  }

  Future<void> loadTasksForDate(DateTime date, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    final normalized = date.normalize;
    state = state.copyWith(currentDate: normalized);
    final s = settings;
    final results = await Future.wait([
      repo.getByDate(
        normalized,
        prioritizeDeadlines: s.prioritizeDeadlines,
        prioritizeOverdue: s.prioritizeOverdue,
      ),
      repo.getOverdue(normalized),
    ]);
    if (!ref.mounted || state.currentDate != normalized) return;
    state = state.copyWith(
      tasks: results[0],
      overdueTasks: results[1],
      isLoading: silent && state.isLoading,
    );
  }

  Future<void> loadUnscheduledTasks({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    final s = settings;
    final unscheduled = await repo.getUnscheduled(
      prioritizeDeadlines: s.prioritizeDeadlines,
      prioritizeOverdue: s.prioritizeOverdue,
    );
    if (!ref.mounted) return;
    state = state.copyWith(
      unscheduledTasks: unscheduled,
      isLoading: silent && state.isLoading,
    );
  }

  Future<void> addTask(TaskDraft draft) async {
    final task = await crudService.buildNewTask(draft);
    final cmd = await crudService.buildCreateWithPropagationCommand(task: task);
    await executeCommand(cmd);
  }

  Future<void> updateTask(Task task, {TaskPlacement? placement}) async {
    final oldTask = await repo.getById(task.id);
    if (oldTask == null) return;
    final updated = await crudService.resolveUpdatedTask(
      task: task,
      placement: placement,
    );
    final cmd = await crudService.buildUpdateWithPropagationCommand(
      previous: oldTask,
      next: updated,
    );
    await executeCommand(cmd);
  }

  Future<void> deleteTask(Task task, {bool deleteSubtasks = true}) async {
    final cmd = await crudService.buildDeleteCommand(
      task: task,
      deleteSubtasks: deleteSubtasks,
    );
    await executeCommand(cmd);
  }

  Future<void> reorderTask(
    Task task,
    String newSortOrder, {
    bool isPlanOrder = false,
  }) async {
    final updated = isPlanOrder
        ? task.copyWith(planSortOrder: newSortOrder)
        : task.copyWith(sortOrder: newSortOrder);
    state = state.applyOptimisticTask(
      updated,
      settings.taskPrefs,
      isPlanOrder: isPlanOrder,
    );
    final cmd = reorderService.buildReorderCommand(
      previous: task,
      next: updated,
    );
    await executeCommand(cmd);
  }

  Future<void> bulkReorderTasks(
    Map<String, String> updates, {
    bool isPlanOrder = false,
  }) async {
    if (updates.isEmpty) return;
    state = state.applyBulkOptimisticReorder(
      updates,
      settings.taskPrefs,
      isPlanOrder: isPlanOrder,
    );
    final cmd = await reorderService.buildBulkReorderCommand(
      updates: updates,
      isPlanOrder: isPlanOrder,
    );
    if (cmd != null) await executeCommand(cmd);
  }

  List<Task> getAllSubtasks(String parentId) => subtaskService.getAllSubtasks(
    parentId: parentId,
    allTasks: state.tasks + state.overdueTasks + state.unscheduledTasks,
  );

  Future<List<Task>> getTasksForProject(String projectId) => repo.getByProject(
    projectId,
    prioritizeDeadlines: settings.prioritizeDeadlines,
  );

  Future<Task?> findById(String id) async =>
      state.getById(id) ?? await repo.getById(id);

  Future<void> refreshTasks() => refreshAll();

  Future<void> refreshAll() async {
    await Future.wait([
      loadTasksForDate(state.currentDate, silent: true),
      loadUnscheduledTasks(silent: true),
    ]);
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(
  TaskNotifier.new,
);
