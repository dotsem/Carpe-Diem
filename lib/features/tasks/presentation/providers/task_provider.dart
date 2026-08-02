import 'dart:async';
import 'dart:math';

import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_bulk_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_history_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TaskNotifier extends Notifier<TaskState> {
  late final ITaskRepository _repo;
  final _uuid = const Uuid();

  TaskState get tasksState => state;

  @override
  TaskState build() {
    _repo = ref.watch(taskRepositoryProvider);

    ref.listen<UndoRedoState>(undoRedoProvider, (previous, next) {
      if (previous != null && previous.isProcessing && !next.isProcessing) {
        if (next.lastOperationType == UndoRedoOperationType.undo ||
            next.lastOperationType == UndoRedoOperationType.redo) {
          _refreshAll();
        }
      }
    });

    return TaskState(currentDate: DateTime.now().normalize);
  }

  Future<void> loadTasksForDate(DateTime date, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    final normalized = date.normalize;
    state = state.copyWith(currentDate: normalized);

    await _autoScheduleDeadlines();

    final settings = ref.read(settingsProvider);
    final tasks = await _repo.getByDate(
      normalized,
      prioritizeDeadlines: settings.prioritizeDeadlines,
    );
    final overdue = await _repo.getOverdue(normalized);

    state = state.copyWith(
      tasks: tasks,
      overdueTasks: overdue,
      isLoading: false,
    );
  }

  Future<void> loadUnscheduledTasks({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    final settings = ref.read(settingsProvider);
    final unscheduled = await _repo.getUnscheduled(
      prioritizeDeadlines: settings.prioritizeDeadlines,
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
    final computedSortOrder = TaskReorderService.computeSortOrder(
      placement: placement,
      activeList: state.tasks,
    );

    DateTime? effectiveScheduledDate = scheduledDate;
    String? effectiveProjectId = projectId;
    if (parentId != null) {
      final parentTask = await _repo.getById(parentId);
      if (parentTask != null) {
        effectiveScheduledDate ??= parentTask.scheduledDate;
        effectiveProjectId ??= parentTask.projectId;
      }
    }

    final resolvedIsUrgent = isUrgent || placement == TaskPlacement.urgent;
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      scheduledDate: effectiveScheduledDate?.normalize,
      projectId: effectiveProjectId,
      isUrgent: resolvedIsUrgent,
      deadline: deadline?.normalize,
      createdAt: DateTime.now(),
      blockedById: blockedById,
      parentId: parentId,
      sortOrder: computedSortOrder,
      labelIds: labelIds,
      tagIds: tagIds,
    );

    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          CreateCommand(
            repo: _repo,
            item: task,
            id: task.id,
            displayName: task.title,
          ),
        );
    final settings = ref.read(settingsProvider);
    if (settings.inheritParentDeadline && task.deadline != null) {
      await DeadlinePropagationService.propagateDeadline(
        repo: _repo,
        task: task,
        inheritParentDeadline: settings.inheritParentDeadline,
      );
    }
    await _refreshAll();
  }

  Future<void> updateTask(Task task, {TaskPlacement? placement}) async {
    final oldTask = await _repo.getById(task.id);
    if (oldTask == null) return;

    var updatedTask = task;
    if (placement != null) {
      final activeList = state.tasks.where((t) => t.id != task.id).toList();
      final computedSortOrder = TaskReorderService.computeSortOrder(
        placement: placement,
        activeList: activeList,
      );
      final resolvedIsUrgent =
          task.isUrgent || placement == TaskPlacement.urgent;
      updatedTask = task.copyWith(
        isUrgent: resolvedIsUrgent,
        sortOrder: computedSortOrder,
      );
    }
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: oldTask,
            next: updatedTask,
            displayName: task.title,
          ),
        );
    final settings = ref.read(settingsProvider);
    if (settings.inheritParentDeadline && task.deadline != null) {
      await DeadlinePropagationService.propagateDeadline(
        repo: _repo,
        task: updatedTask,
        inheritParentDeadline: settings.inheritParentDeadline,
      );
    }
    await _refreshAll();
  }

  Future<void> deleteTask(Task task) async {
    final subtasks = await SubtaskService.getAllSubtasksFromRepo(
      repo: _repo,
      parentId: task.id,
    );
    if (subtasks.isEmpty) {
      await ref
          .read(undoRedoProvider.notifier)
          .execute(
            DeleteCommand(
              repo: _repo,
              item: task,
              id: task.id,
              displayName: task.title,
            ),
          );
    } else {
      final commands = <Command>[];
      for (final subtask in subtasks) {
        commands.add(
          DeleteCommand(
            repo: _repo,
            item: subtask,
            id: subtask.id,
            displayName: subtask.title,
          ),
        );
      }
      commands.add(
        DeleteCommand(
          repo: _repo,
          item: task,
          id: task.id,
          displayName: task.title,
        ),
      );
      final compound = CompoundCommand(
        commands,
        'Delete "${task.title}" and ${subtasks.length} subtask(s)',
      );
      await ref.read(undoRedoProvider.notifier).execute(compound);
    }
    await _refreshAll();
  }

  Future<void> reorderTask(Task task, String newSortOrder) async {
    final updated = task.copyWith(sortOrder: newSortOrder);
    final settings = ref.read(settingsProvider);
    state = state.copyWith(
      tasks: TaskReorderService.optimisticallyReorder(
        currentList: state.tasks,
        updatedTask: updated,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
      overdueTasks: TaskReorderService.optimisticallyReorder(
        currentList: state.overdueTasks,
        updatedTask: updated,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
      unscheduledTasks: TaskReorderService.optimisticallyReorder(
        currentList: state.unscheduledTasks,
        updatedTask: updated,
        prioritizeOverdue: settings.prioritizeOverdue,
        prioritizeDeadlines: settings.prioritizeDeadlines,
      ),
    );

    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: task,
            next: updated,
            displayName: task.title,
            customDescription:
                'Reorder ${_repo.repositoryName}: "${task.title}"',
          ),
        );
    await _refreshAll();
  }

  Future<void> bulkReorderTasks(Map<String, String> updates) async {
    if (updates.isEmpty) return;
    final settings = ref.read(settingsProvider);
    var currentTasks = List<Task>.from(state.tasks);
    var currentOverdue = List<Task>.from(state.overdueTasks);
    var currentUnscheduled = List<Task>.from(state.unscheduledTasks);

    final commands = <Command>[];

    for (final entry in updates.entries) {
      final taskId = entry.key;
      final newSortOrder = entry.value;

      Task? findAndApply(List<Task> list) {
        final idx = list.indexWhere((t) => t.id == taskId);
        if (idx != -1) {
          final updated = list[idx].copyWith(sortOrder: newSortOrder);
          list[idx] = updated;
          return updated;
        }
        return null;
      }

      final updatedTask =
          findAndApply(currentTasks) ??
          findAndApply(currentOverdue) ??
          findAndApply(currentUnscheduled);

      if (updatedTask != null) {
        currentTasks = TaskReorderService.optimisticallyReorder(
          currentList: currentTasks,
          updatedTask: updatedTask,
          prioritizeOverdue: settings.prioritizeOverdue,
          prioritizeDeadlines: settings.prioritizeDeadlines,
        );
        currentOverdue = TaskReorderService.optimisticallyReorder(
          currentList: currentOverdue,
          updatedTask: updatedTask,
          prioritizeOverdue: settings.prioritizeOverdue,
          prioritizeDeadlines: settings.prioritizeDeadlines,
        );
        currentUnscheduled = TaskReorderService.optimisticallyReorder(
          currentList: currentUnscheduled,
          updatedTask: updatedTask,
          prioritizeOverdue: settings.prioritizeOverdue,
          prioritizeDeadlines: settings.prioritizeDeadlines,
        );
      }

      final oldTask = await _repo.getById(taskId);
      if (oldTask != null) {
        final updated = oldTask.copyWith(sortOrder: newSortOrder);
        commands.add(
          UpdateCommand(
            repo: _repo,
            previous: oldTask,
            next: updated,
            displayName: oldTask.title,
            customDescription:
                'Reorder ${_repo.repositoryName}: "${oldTask.title}"',
          ),
        );
      }
    }

    state = state.copyWith(
      tasks: currentTasks,
      overdueTasks: currentOverdue,
      unscheduledTasks: currentUnscheduled,
    );

    if (commands.isNotEmpty) {
      if (commands.length == 1) {
        await ref.read(undoRedoProvider.notifier).execute(commands.first);
      } else {
        final compound = CompoundCommand(
          commands,
          'Reorder ${commands.length} tasks',
        );
        await ref.read(undoRedoProvider.notifier).execute(compound);
      }
    }

    await _refreshAll();
  }

  Future<void> updateTaskStatus(Task task, TaskStatus status) async {
    final updated = task.copyWith(status: status);
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: task,
            next: updated,
            displayName: task.title,
          ),
        );
    await _refreshAll();
  }

  Future<void> startTask(Task task) async {
    final updated = task.copyWith(
      status: TaskStatus.inProgress,
      scheduledDate: task.scheduledDate ?? DateTime.now().normalize,
    );
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: task,
            next: updated,
            displayName: task.title,
          ),
        );
    await _refreshAll();
  }

  Future<SubtaskCompletionConflict?> checkSubtaskConflict(Task task) =>
      SubtaskService.checkSubtaskConflict(repo: _repo, task: task);

  Future<void> completeTask(Task task) async {
    final updated = task.copyWith(
      status: TaskStatus.done,
      scheduledDate: task.scheduledDate ?? DateTime.now().normalize,
      completedAt: DateTime.now(),
    );
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: task,
            next: updated,
            displayName: task.title,
          ),
        );

    if (task.parentId != null) {
      await SubtaskService.checkAndAutoCompleteParent(
        repo: _repo,
        parentId: task.parentId!,
        onCompleteParent: completeTask,
      );
    }

    await cleanupHistory();
    await _refreshAll();
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
        if (conflict != null) {
          return conflict;
        }
        if (useTimer) {
          final settings = ref.read(settingsProvider);
          timerNotifier.startPending(
            task.id,
            settings.taskCompletionDelay,
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

  List<Task> getAllSubtasks(String parentId) => SubtaskService.getAllSubtasks(
    parentId: parentId,
    allTasks: [
      ...state.tasks,
      ...state.overdueTasks,
      ...state.unscheduledTasks,
    ],
  );

  Future<List<Task>> getAllSubtasksFromRepo(String parentId) =>
      SubtaskService.getAllSubtasksFromRepo(repo: _repo, parentId: parentId);

  Future<void> rescheduleOverdue(Task task, DateTime newDate) async {
    final updated = task.copyWith(scheduledDate: newDate.normalize);
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: task,
            next: updated,
            displayName: task.title,
          ),
        );
    await _refreshAll();
  }

  Future<void> unScheduleTask(Task task, {bool resetStatus = false}) async {
    final updated = task.copyWith(
      clearScheduledDate: true,
      status: resetStatus ? TaskStatus.todo : task.status,
    );
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: task,
            next: updated,
            displayName: task.title,
          ),
        );
    await _refreshAll();
  }

  Future<void> _scheduleTasksForDate(
    List<String> taskIds,
    DateTime date,
  ) async {
    final normalizedDate = date.normalize;
    for (final id in taskIds) {
      Task? task;
      try {
        task = state.tasks.firstWhere(
          (t) => t.id == id,
          orElse: () => state.overdueTasks.firstWhere(
            (t) => t.id == id,
            orElse: () => state.unscheduledTasks.firstWhere((t) => t.id == id),
          ),
        );
      } catch (_) {
        task = await _repo.getById(id);
      }

      if (task != null) {
        final updated = task.copyWith(scheduledDate: normalizedDate);
        await _repo.update(updated);
      }
    }
    await _refreshAll();
  }

  Future<void> scheduleTasksForToday(List<String> taskIds) async {
    await _scheduleTasksForDate(taskIds, DateTime.now());
    ToastUtils.showSuccess('Tasks scheduled for today');
  }

  Future<void> scheduleTasksForTomorrow(List<String> taskIds) async {
    await _scheduleTasksForDate(
      taskIds,
      DateTime.now().add(const Duration(days: 1)),
    );
    ToastUtils.showSuccess('Tasks scheduled for tomorrow');
  }

  Future<void> scheduleTasksForNextDay(
    List<String> taskIds,
    DateTime selectedDate,
  ) async {
    final nextDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + 1,
    );
    final normalizedDate = nextDay.normalize;
    await _scheduleTasksForDate(taskIds, normalizedDate);
    final formattedDate = DateFormat('MMM d').format(normalizedDate);
    ToastUtils.showSuccess('Tasks scheduled for $formattedDate');
  }

  Future<void> scheduleTasksForNextWorkDay(List<String> taskIds) async {
    final settings = ref.read(settingsProvider);
    DateTime nextStartOfWeek = DateTime.now().next(settings.firstDayOfWeek);
    await _scheduleTasksForDate(taskIds, nextStartOfWeek);
    ToastUtils.showSuccess('Tasks scheduled for next week');
  }

  Future<Task?> pickAndScheduleRandomTask(List<Task> availableTasks) async {
    final unblockedTasks = availableTasks
        .where((t) => t.blockedById == null && !t.isCompleted)
        .toList();
    if (unblockedTasks.isEmpty) return null;

    final randomTask = unblockedTasks[Random().nextInt(unblockedTasks.length)];
    await scheduleTasksForToday([randomTask.id]);
    return randomTask;
  }

  Future<void> bulkUpdateTasks({
    required List<String> taskIds,
    bool? isUrgent,
    bool updateUrgent = false,
    DateTime? scheduledDate,
    bool updateScheduledDate = false,
    bool clearScheduledDate = false,
    String? projectId,
    bool updateProjectId = false,
    bool clearProjectId = false,
    DateTime? deadline,
    bool updateDeadline = false,
    bool clearDeadline = false,
    String? blockedById,
    bool updateBlockedById = false,
    bool clearBlockedById = false,
  }) async {
    final allCurrentStateTasks = [
      ...state.tasks,
      ...state.overdueTasks,
      ...state.unscheduledTasks,
    ];
    await ref
        .read(taskBulkProvider.notifier)
        .bulkUpdateTasks(
          taskIds: taskIds,
          currentStateTasks: allCurrentStateTasks,
          onRefresh: _refreshAll,
          isUrgent: isUrgent,
          updateUrgent: updateUrgent,
          scheduledDate: scheduledDate,
          updateScheduledDate: updateScheduledDate,
          clearScheduledDate: clearScheduledDate,
          projectId: projectId,
          updateProjectId: updateProjectId,
          clearProjectId: clearProjectId,
          deadline: deadline,
          updateDeadline: updateDeadline,
          clearDeadline: clearDeadline,
          blockedById: blockedById,
          updateBlockedById: updateBlockedById,
          clearBlockedById: clearBlockedById,
        );
  }

  Future<void> bulkDeleteTasks(List<String> taskIds) => ref
      .read(taskBulkProvider.notifier)
      .bulkDeleteTasks(taskIds: taskIds, onRefresh: _refreshAll);

  Future<void> importTasksFromMarkdown(String markdown, String? projectId) =>
      ref
          .read(taskBulkProvider.notifier)
          .importTasksFromMarkdown(
            markdown: markdown,
            projectId: projectId,
            onRefresh: _refreshAll,
          );

  Future<void> cleanupHistory() => ref
      .read(taskHistoryProvider.notifier)
      .cleanupHistory(onCleanup: _refreshAll);

  Future<List<Task>> getCompletedTasks(
    DateTime start,
    DateTime end, {
    int? limit,
    int? offset,
    TaskFilter? filter,
  }) => ref
      .read(taskHistoryProvider.notifier)
      .getCompletedTasks(
        start,
        end,
        limit: limit,
        offset: offset,
        filter: filter,
      );

  Future<DateTime> getFirstTaskDate() =>
      ref.read(taskHistoryProvider.notifier).getFirstTaskDate();

  Future<HistoryOverview> getHistoryOverview(
    DateTime start,
    DateTime end, {
    TaskFilter? filter,
  }) => ref
      .read(taskHistoryProvider.notifier)
      .getHistoryOverview(start, end, filter: filter);

  Future<void> completeParentWithCascade(
    SubtaskCompletionConflict conflict,
  ) async {
    final now = DateTime.now();
    final commands = <Command>[];

    for (final subtask in conflict.incompleteSubtasks) {
      final updatedSubtask = subtask.copyWith(
        status: TaskStatus.done,
        scheduledDate: subtask.scheduledDate ?? now.normalize,
        completedAt: now,
      );
      commands.add(
        UpdateCommand(
          repo: _repo,
          previous: subtask,
          next: updatedSubtask,
          displayName: subtask.title,
        ),
      );
    }

    final updatedParent = conflict.parentTask.copyWith(
      status: TaskStatus.done,
      scheduledDate: conflict.parentTask.scheduledDate ?? now.normalize,
      completedAt: now,
    );
    commands.add(
      UpdateCommand(
        repo: _repo,
        previous: conflict.parentTask,
        next: updatedParent,
        displayName: conflict.parentTask.title,
      ),
    );

    final compound = CompoundCommand(
      commands,
      'Complete "${conflict.parentTask.title}" and ${conflict.incompleteSubtasks.length} subtasks',
    );
    await ref.read(undoRedoProvider.notifier).execute(compound);
    await cleanupHistory();
    await _refreshAll();
  }

  Future<void> completeParentOnly(Task parentTask) async {
    await completeTask(parentTask);
  }

  Future<List<Task>> getTasksForProject(String projectId) async {
    final settings = ref.read(settingsProvider);
    return _repo.getByProject(
      projectId,
      prioritizeDeadlines: settings.prioritizeDeadlines,
    );
  }

  Future<List<Task>> getBacklog() async {
    final settings = ref.read(settingsProvider);
    return _repo.getUnscheduled(
      prioritizeDeadlines: settings.prioritizeDeadlines,
    );
  }

  Future<List<Task>> getTasksForLabel(String labelId) async {
    final settings = ref.read(settingsProvider);
    return _repo.getByLabel(
      labelId,
      prioritizeDeadlines: settings.prioritizeDeadlines,
    );
  }

  Future<void> refreshTasks() => _refreshAll();

  Future<void> _refreshAll() async {
    await loadTasksForDate(state.currentDate, silent: true);
    await loadUnscheduledTasks(silent: true);
  }

  Future<void> _autoScheduleDeadlines() async {
    final backlog = await _repo.getUnscheduled();
    final today = DateTime.now().normalize;

    for (final task in backlog) {
      if (task.deadline != null) {
        final normalizedDeadline = task.deadline!.normalize;
        if (normalizedDeadline.isBefore(today.add(const Duration(days: 1)))) {
          final updated = task.copyWith(scheduledDate: normalizedDeadline);
          await _repo.update(updated);
        }
      }
    }
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() {
  return TaskNotifier();
});
