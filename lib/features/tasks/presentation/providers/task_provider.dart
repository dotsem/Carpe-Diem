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
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_markdown_parser.dart';

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
    Priority priority = Priority.none,
    DateTime? deadline,
    String? blockedById,
    List<String> labelIds = const [],
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      scheduledDate: scheduledDate != null ? _normalizeDate(scheduledDate) : null,
      projectId: projectId,
      priority: priority,
      deadline: deadline != null ? _normalizeDate(deadline) : null,
      createdAt: DateTime.now(),
      blockedById: blockedById,
      labelIds: labelIds,
    );

    await ref
        .read(undoRedoProvider.notifier)
        .execute(CreateCommand(repo: _repo, item: task, id: task.id, displayName: task.title));
    final settings = ref.read(settingsProvider);
    if (settings.inheritParentDeadline && task.deadline != null) {
      await _propagateDeadline(task);
    }
    await _refreshAll();
    ToastUtils.showSuccess('Task "$title" created');
  }

  Future<void> updateTaskStatus(Task task, TaskStatus status) async {
    final updated = task.copyWith(status: status);
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: task, next: updated, displayName: task.title));
    await _refreshAll();
    ToastUtils.showSuccess('Task status updated to ${status.name}');
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

  Future<void> updateTask(Task task) async {
    final oldTask = await _repo.getById(task.id);
    if (oldTask == null) return;
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: oldTask, next: task, displayName: task.title));
    final settings = ref.read(settingsProvider);
    if (settings.inheritParentDeadline && task.deadline != null) {
      await _propagateDeadline(task);
    }
    await _refreshAll();
    ToastUtils.showSuccess('Task "${task.title}" updated');
  }

  Future<void> deleteTask(Task task) async {
    await ref
        .read(undoRedoProvider.notifier)
        .execute(DeleteCommand(repo: _repo, item: task, id: task.id, displayName: task.title));
    await _refreshAll();
    ToastUtils.showSuccess('Task "${task.title}" deleted');
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
    ToastUtils.showSuccess('Task "${task.title}" unscheduled');
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

  Future<void> _refreshAll() async {
    await loadTasksForDate(state.currentDate, silent: true);
    await loadUnscheduledTasks(silent: true);
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() {
  return TaskNotifier();
});
