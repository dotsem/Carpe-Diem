import 'dart:async';
import 'dart:math';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_markdown_parser.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';

part 'task_provider_extensions.dart';

class TaskState {
  final List<Task> tasks;
  final List<Task> overdueTasks;
  final List<Task> unscheduledTasks;
  final bool isLoading;
  final DateTime currentDate;

  const TaskState({
    this.tasks = const [],
    this.overdueTasks = const [],
    this.unscheduledTasks = const [],
    this.isLoading = false,
    required this.currentDate,
  });

  TaskState copyWith({
    List<Task>? tasks,
    List<Task>? overdueTasks,
    List<Task>? unscheduledTasks,
    bool? isLoading,
    DateTime? currentDate,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      unscheduledTasks: unscheduledTasks ?? this.unscheduledTasks,
      isLoading: isLoading ?? this.isLoading,
      currentDate: currentDate ?? this.currentDate,
    );
  }
}

class TaskNotifier extends Notifier<TaskState> {
  late final ITaskRepository _repo;
  late final IProjectRepository _projectRepo;
  late final IHistoryRepository _historyRepo;
  final _uuid = const Uuid();

  TaskState get tasksState => state;

  @override
  TaskState build() {
    _repo = ref.watch(taskRepositoryProvider);
    _projectRepo = ref.watch(projectRepositoryProvider);
    _historyRepo = ref.watch(historyRepositoryProvider);

    ref.listen<UndoRedoState>(undoRedoProvider, (previous, next) {
      if (previous != null && previous.isProcessing && !next.isProcessing) {
        if (next.lastOperationType == UndoRedoOperationType.undo ||
            next.lastOperationType == UndoRedoOperationType.redo) {
          _refreshAll();
        }
      }
    });

    return TaskState(currentDate: _normalizeDate(DateTime.now()));
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> loadTasksForDate(DateTime date, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    final normalized = _normalizeDate(date);
    state = state.copyWith(currentDate: normalized);

    await _autoScheduleDeadlines();

    final settings = ref.read(settingsProvider);
    final tasks = await _repo.getByDate(normalized, prioritizeDeadlines: settings.prioritizeDeadlines);
    final overdue = await _repo.getOverdue(normalized);

    state = state.copyWith(tasks: tasks, overdueTasks: overdue, isLoading: false);
  }

  Future<void> loadUnscheduledTasks({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    final settings = ref.read(settingsProvider);
    final unscheduled = await _repo.getUnscheduled(prioritizeDeadlines: settings.prioritizeDeadlines);

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
    TaskPlacement placement = TaskPlacement.bottom,
    List<String> labelIds = const [],
    List<String> tagIds = const [],
  }) async {

    String computedSortOrder;
    final activeList = state.tasks;
    switch (placement) {
      case TaskPlacement.top || TaskPlacement.urgent:
        computedSortOrder = LexoRankUtils.generateTop(activeList.firstOrNull?.sortOrder);
      case TaskPlacement.middle:
        computedSortOrder = LexoRankUtils.generateMiddle(
          activeList.firstOrNull?.sortOrder,
          activeList.lastOrNull?.sortOrder,
        );
      default:
        computedSortOrder = LexoRankUtils.generateBottom(activeList.lastOrNull?.sortOrder);
    }

    final resolvedIsUrgent = isUrgent || placement == TaskPlacement.urgent;
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      scheduledDate: scheduledDate != null ? _normalizeDate(scheduledDate) : null,
      projectId: projectId,
      isUrgent: resolvedIsUrgent,
      deadline: deadline != null ? _normalizeDate(deadline) : null,
      createdAt: DateTime.now(),
      blockedById: blockedById,
      sortOrder: computedSortOrder,
      labelIds: labelIds,
      tagIds: tagIds,
    );

    await ref
        .read(undoRedoProvider.notifier)
        .execute(CreateCommand(repo: _repo, item: task, id: task.id, displayName: task.title));
    final settings = ref.read(settingsProvider);
    if (settings.inheritParentDeadline && task.deadline != null) {
      await _propagateDeadline(task);
    }
    await _refreshAll();
  }

  Future<void> reorderTask(Task task, String newSortOrder) async {
    final updated = task.copyWith(sortOrder: newSortOrder);
    state = state.copyWith(
      tasks: _optimisticallyReorder(state.tasks, updated),
      overdueTasks: _optimisticallyReorder(state.overdueTasks, updated),
      unscheduledTasks: _optimisticallyReorder(state.unscheduledTasks, updated),
    );

    await _repo.update(updated);
    await _refreshAll();
  }

  Future<void> bulkReorderTasks(Map<String, String> updates) async {
    if (updates.isEmpty) return;
    var currentTasks = List<Task>.from(state.tasks);
    var currentOverdue = List<Task>.from(state.overdueTasks);
    var currentUnscheduled = List<Task>.from(state.unscheduledTasks);

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
          findAndApply(currentTasks) ?? findAndApply(currentOverdue) ?? findAndApply(currentUnscheduled);

      if (updatedTask != null) {
        currentTasks = _optimisticallyReorder(currentTasks, updatedTask);
        currentOverdue = _optimisticallyReorder(currentOverdue, updatedTask);
        currentUnscheduled = _optimisticallyReorder(currentUnscheduled, updatedTask);
      }
    }

    state = state.copyWith(tasks: currentTasks, overdueTasks: currentOverdue, unscheduledTasks: currentUnscheduled);
    for (final entry in updates.entries) {
      final task = await _repo.getById(entry.key);
      if (task != null) {
        await _repo.update(task.copyWith(sortOrder: entry.value));
      }
    }
    await _refreshAll();
  }

  List<Task> _optimisticallyReorder(List<Task> currentList, Task updatedTask) {
    if (!currentList.any((t) => t.id == updatedTask.id)) return currentList;

    final updatedList = currentList.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
    updatedList.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;

      final settings = ref.read(settingsProvider);

      if (settings.prioritizeOverdue) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
      }

      final deadlineComp = () {
        if (a.deadline == b.deadline) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      }();

      if (settings.prioritizeDeadlines && deadlineComp != 0) {
        return deadlineComp;
      }

      final sortComp = a.sortOrder.compareTo(b.sortOrder);
      if (sortComp != 0) return sortComp;

      return b.createdAt.compareTo(a.createdAt);
    });
    return updatedList;
  }

  Future<void> updateTaskStatus(Task task, TaskStatus status) async {
    final updated = task.copyWith(status: status);
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: task, next: updated, displayName: task.title));
    await _refreshAll();
  }

  Future<void> startTask(Task task) async {
    final updated = task.copyWith(status: TaskStatus.inProgress, scheduledDate: _normalizeDate(DateTime.now()));
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: task, next: updated, displayName: task.title));
    await _refreshAll();
  }

  Future<void> completeTask(Task task) async {
    final updated = task.copyWith(
      status: TaskStatus.done,
      scheduledDate: task.scheduledDate ?? _normalizeDate(DateTime.now()),
      completedAt: DateTime.now(),
    );
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: task, next: updated, displayName: task.title));
    await cleanupHistory();
    await _refreshAll();
  }

  Future<void> toggleComplete(Task task, {bool useTimer = false}) async {
    final timerNotifier = ref.read(taskTimerProvider.notifier);
    if (timerNotifier.isTaskPending(task.id)) {
      timerNotifier.cancelPending(task.id);
      return;
    }

    switch (task.status) {
      case TaskStatus.todo:
        await startTask(task);
        break;
      case TaskStatus.inProgress:
        if (useTimer) {
          final settings = ref.read(settingsProvider);
          timerNotifier.startPending(task.id, settings.taskCompletionDelay, () => completeTask(task));
        } else {
          await completeTask(task);
        }
        break;
      case TaskStatus.done:
        await updateTaskStatus(task, TaskStatus.todo);
        break;
    }
  }

  Future<void> updateTask(Task task, {TaskPlacement? placement}) async {
    final oldTask = await _repo.getById(task.id);
    if (oldTask == null) return;

    var updatedTask = task;
    if (placement != null) {
      String computedSortOrder;
      final activeList = state.tasks.where((t) => t.id != task.id).toList();
      switch (placement) {
        case TaskPlacement.top || TaskPlacement.urgent:
          computedSortOrder = LexoRankUtils.generateTop(activeList.firstOrNull?.sortOrder);
        case TaskPlacement.middle:
          computedSortOrder = LexoRankUtils.generateMiddle(
            activeList.firstOrNull?.sortOrder,
            activeList.lastOrNull?.sortOrder,
          );
        default:
          computedSortOrder = LexoRankUtils.generateBottom(activeList.lastOrNull?.sortOrder);
      }
      final resolvedIsUrgent = task.isUrgent || placement == TaskPlacement.urgent;
      updatedTask = task.copyWith(isUrgent: resolvedIsUrgent, sortOrder: computedSortOrder);
    }
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: oldTask, next: updatedTask, displayName: task.title));
    final settings = ref.read(settingsProvider);
    if (settings.inheritParentDeadline && task.deadline != null) {
      await _propagateDeadline(updatedTask);
    }
    await _refreshAll();
  }

  Future<void> deleteTask(Task task) async {
    await ref
        .read(undoRedoProvider.notifier)
        .execute(DeleteCommand(repo: _repo, item: task, id: task.id, displayName: task.title));
    await _refreshAll();
  }

  Future<void> rescheduleOverdue(Task task, DateTime newDate) async {
    final updated = task.copyWith(scheduledDate: _normalizeDate(newDate));
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: task, next: updated, displayName: task.title));
    await _refreshAll();
  }

  Future<void> unScheduleTask(Task task, {bool resetStatus = false}) async {
    final updated = task.copyWith(clearScheduledDate: true, status: resetStatus ? TaskStatus.todo : task.status);
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: task, next: updated, displayName: task.title));
    await _refreshAll();
  }

  Future<List<Task>> getTasksForProject(String projectId) async {
    final settings = ref.read(settingsProvider);
    return _repo.getByProject(projectId, prioritizeDeadlines: settings.prioritizeDeadlines);
  }

  Future<List<Task>> getBacklog() async {
    final settings = ref.read(settingsProvider);
    return _repo.getUnscheduled(prioritizeDeadlines: settings.prioritizeDeadlines);
  }

  Future<List<Task>> getTasksForLabel(String labelId) async {
    final settings = ref.read(settingsProvider);
    return _repo.getByLabel(labelId, prioritizeDeadlines: settings.prioritizeDeadlines);
  }

  Future<void> refreshTasks() => _refreshAll();

  Future<void> _refreshAll() async {
    await loadTasksForDate(state.currentDate, silent: true);
    await loadUnscheduledTasks(silent: true);
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() {
  return TaskNotifier();
});
