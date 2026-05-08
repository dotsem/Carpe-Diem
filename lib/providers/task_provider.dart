import 'dart:async';
import 'dart:math';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/data/models/history_overview.dart';
import 'package:carpe_diem/data/models/task_layout.dart';
import 'package:carpe_diem/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_status.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/data/repositories/task_repository.dart';
import 'package:carpe_diem/data/repositories/project_repository.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo = TaskRepository();
  final ProjectRepository _projectRepo = ProjectRepository();
  final SettingsProvider _settingsProvider;
  final _uuid = const Uuid();

  TaskProvider(this._settingsProvider) {
    _layoutMode = _settingsProvider.getTaskLayout();
  }

  void refreshLayout() {
    final newMode = _settingsProvider.getTaskLayout();
    if (_layoutMode != newMode) {
      _layoutMode = newMode;
      notifyListeners();
    }
  }

  final Map<String, DateTime> _pendingCompletions = {};
  final Map<String, Timer> _completionTimers = {};

  List<Task> _tasks = [];
  List<Task> _overdueTasks = [];
  List<Task> _unscheduledTasks = [];
  bool _isLoading = false;
  DateTime _currentDate = DateTime.now();
  late TaskLayout _layoutMode;

  List<Task> get tasks => _tasks;
  List<Task> get overdueTasks => _overdueTasks;
  List<Task> get unscheduledTasks => _unscheduledTasks;
  bool get isLoading => _isLoading;
  TaskLayout get layoutMode => _layoutMode;

  void toggleLayoutMode() {
    _layoutMode = _layoutMode == TaskLayout.list ? TaskLayout.kanban : TaskLayout.list;
    _settingsProvider.setTaskLayout(_layoutMode);
    notifyListeners();
  }

  Future<void> loadTasksForDate(DateTime date, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _currentDate = _normalizeDate(date);

    await _autoScheduleDeadlines();

    _tasks = await _repo.getByDate(_currentDate, prioritizeDeadlines: _settingsProvider.prioritizeDeadlines);
    _overdueTasks = await _repo.getOverdue(_currentDate);

    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadUnscheduledTasks({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    _unscheduledTasks = await _repo.getUnscheduled(prioritizeDeadlines: _settingsProvider.prioritizeDeadlines);

    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
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

    await _repo.insert(task);
    if (_settingsProvider.inheritParentDeadline && task.deadline != null) {
      await _propagateDeadline(task);
    }
    await loadTasksForDate(_currentDate);
    await loadUnscheduledTasks();
    ToastUtils.showSuccess('Task "$title" created');
  }

  Future<void> updateTaskStatus(Task task, TaskStatus status) async {
    final updated = task.copyWith(status: status);
    await _repo.update(updated);
    await _refreshAll();
    ToastUtils.showSuccess('Task status updated to ${status.name}');
  }

  Future<void> startTask(Task task) async {
    final updated = task.copyWith(status: TaskStatus.inProgress, scheduledDate: _normalizeDate(DateTime.now()));
    await _repo.update(updated);
    await _refreshAll();
  }

  Future<void> completeTask(Task task) async {
    final updated = task.copyWith(
      status: TaskStatus.done,
      scheduledDate: task.scheduledDate ?? _normalizeDate(DateTime.now()),
      completedAt: DateTime.now(),
    );
    await _repo.update(updated);
    await cleanupHistory();
    await _refreshAll();
  }

  Future<void> cleanupHistory() async {
    final days = _settingsProvider.historyRetention;
    if (days > 0) {
      final deletedCount = await _repo.cleanupHistory(days);
      if (deletedCount > 0) {
        await _refreshAll();
      }
    }
  }

  Future<void> toggleComplete(Task task, {bool useTimer = false}) async {
    if (_pendingCompletions.containsKey(task.id)) {
      _cancelPending(task.id);
      return;
    }

    switch (task.status) {
      case TaskStatus.todo:
        await startTask(task);
        break;
      case TaskStatus.inProgress:
        if (useTimer) {
          _startPending(task);
        } else {
          await completeTask(task);
        }
        break;
      case TaskStatus.done:
        await updateTaskStatus(task, TaskStatus.todo);
        break;
    }
  }

  void _startPending(Task task) {
    _pendingCompletions[task.id] = DateTime.now();
    _completionTimers[task.id] = Timer(Duration(seconds: _settingsProvider.taskCompletionDelay), () {
      _pendingCompletions.remove(task.id);
      _completionTimers.remove(task.id);
      completeTask(task);
    });
    notifyListeners();
  }

  void _cancelPending(String taskId) {
    _completionTimers[taskId]?.cancel();
    _completionTimers.remove(taskId);
    _pendingCompletions.remove(taskId);
    notifyListeners();
  }

  bool isTaskPending(String taskId) => _pendingCompletions.containsKey(taskId);

  double getPendingProgress(String taskId) {
    final startTime = _pendingCompletions[taskId];
    if (startTime == null) return 0.0;
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final total = _settingsProvider.taskCompletionDelay * 1000;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Future<void> updateTask(Task task) async {
    await _repo.update(task);
    if (_settingsProvider.inheritParentDeadline && task.deadline != null) {
      await _propagateDeadline(task);
    }
    await _refreshAll();
    ToastUtils.showSuccess('Task "${task.title}" updated');
  }

  Future<void> deleteTask(Task task) async {
    await _repo.delete(task.id);
    await _refreshAll();
    ToastUtils.showSuccess('Task "${task.title}" deleted');
  }

  Future<void> rescheduleOverdue(Task task, DateTime newDate) async {
    final updated = task.copyWith(scheduledDate: _normalizeDate(newDate));
    await _repo.update(updated);
    await _refreshAll();
  }

  Future<void> unScheduleTask(Task task, {bool resetStatus = false}) async {
    final updated = task.copyWith(clearScheduledDate: true, status: resetStatus ? TaskStatus.todo : task.status);
    await _repo.update(updated);
    await _refreshAll();
    ToastUtils.showSuccess('Task "${task.title}" unscheduled');
  }

  Future<List<Task>> getTasksForProject(String projectId) async {
    return _repo.getByProject(projectId, prioritizeDeadlines: _settingsProvider.prioritizeDeadlines);
  }

  Future<List<Task>> getBacklog() async {
    return _repo.getUnscheduled(prioritizeDeadlines: _settingsProvider.prioritizeDeadlines);
  }

  Future<List<Task>> getTasksForLabel(String labelId) async {
    return _repo.getByLabel(labelId, prioritizeDeadlines: _settingsProvider.prioritizeDeadlines);
  }

  Future<void> bulkUpdateTasks({
    required List<String> taskIds,
    Priority? priority,
    bool updatePriority = false,
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
    DateTime? projectDeadline;
    bool shouldInheritDeadline = false;
    if (updateProjectId && projectId != null && _settingsProvider.inheritProjectDeadline) {
      final project = await _projectRepo.getById(projectId);
      if (project?.deadline != null) {
        projectDeadline = project!.deadline;
        shouldInheritDeadline = true;
      }
    }

    for (final id in taskIds) {
      Task? task;
      try {
        task = _tasks.firstWhere(
          (t) => t.id == id,
          orElse: () => _overdueTasks.firstWhere(
            (t) => t.id == id,
            orElse: () => _unscheduledTasks.firstWhere((t) => t.id == id),
          ),
        );
      } catch (_) {
        task = await _repo.getById(id);
      }

      if (task != null) {
        final updated = task.copyWith(
          priority: updatePriority ? priority : null,
          scheduledDate: updateScheduledDate ? scheduledDate : null,
          clearScheduledDate: clearScheduledDate,
          projectId: updateProjectId ? projectId : null,
          clearProjectId: clearProjectId,
          deadline: updateDeadline ? deadline : (shouldInheritDeadline ? projectDeadline : null),
          clearDeadline: clearDeadline,
          blockedById: updateBlockedById ? blockedById : null,
          clearBlockedBy: clearBlockedById,
        );
        await _repo.update(updated);
        if (_settingsProvider.inheritParentDeadline && updated.deadline != null) {
          await _propagateDeadline(updated);
        }
      }
    }
    await _refreshAll();
    ToastUtils.showSuccess("Updated ${taskIds.length} tasks");
  }

  Future<void> bulkDeleteTasks(List<String> taskIds) async {
    for (final id in taskIds) {
      await _repo.delete(id);
    }
    await _refreshAll();
    ToastUtils.showSuccess('Deleted ${taskIds.length} tasks');
  }

  Future<void> _refreshAll() async {
    await loadTasksForDate(_currentDate, silent: true);
    await loadUnscheduledTasks(silent: true);
  }

  Future<void> _scheduleTasksForDate(List<String> taskIds, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    for (final id in taskIds) {
      Task? task;
      try {
        task = _tasks.firstWhere(
          (t) => t.id == id,
          orElse: () => _overdueTasks.firstWhere(
            (t) => t.id == id,
            orElse: () => _unscheduledTasks.firstWhere((t) => t.id == id),
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
    await _scheduleTasksForDate(taskIds, DateTime.now().add(const Duration(days: 1)));
    ToastUtils.showSuccess('Tasks scheduled for tomorrow');
  }

  Future<void> scheduleTasksForNextWorkDay(List<String> taskIds) async {
    DateTime nextStartOfWeek = DateTime.now().next(_settingsProvider.firstDayOfWeek);
    await _scheduleTasksForDate(taskIds, nextStartOfWeek);
    ToastUtils.showSuccess('Tasks scheduled for next week');
  }

  Future<Task?> pickAndScheduleRandomTask(List<Task> availableTasks) async {
    final unblockedTasks = availableTasks.where((t) => t.blockedById == null && !t.isCompleted).toList();
    if (unblockedTasks.isEmpty) return null;

    final randomTask = unblockedTasks[Random().nextInt(unblockedTasks.length)];
    await scheduleTasksForToday([randomTask.id]);
    return randomTask;
  }

  Future<List<Task>> getCompletedTasks(
    DateTime start,
    DateTime end, {
    int? limit,
    int? offset,
    TaskFilter? filter,
  }) async {
    return _repo.getCompletedInRange(start, end, limit: limit, offset: offset, filter: filter);
  }

  Future<DateTime> getFirstTaskDate() async {
    final firstCompleted = await _repo.getFirstCompletedDate();
    if (firstCompleted != null) return firstCompleted;

    // Fallback to today if no tasks are completed
    return DateTime.now();
  }

  Future<HistoryOverview> getHistoryOverview(DateTime start, DateTime end, {TaskFilter? filter}) async {
    return _repo.getHistoryOverview(start, end, filter: filter);
  }

  Future<void> importTasksFromMarkdown(String markdown, String? projectId) async {
    final tasks = _parseMarkdown(markdown);
    DateTime? projectDeadline;
    if (projectId != null && _settingsProvider.inheritProjectDeadline) {
      final project = await _projectRepo.getById(projectId);
      projectDeadline = project?.deadline;
    }

    for (final task in tasks) {
      await _repo.insert(task.copyWith(projectId: projectId, deadline: projectDeadline));
    }
    await _refreshAll();
    ToastUtils.showSuccess('Imported ${tasks.length} tasks from markdown');
  }

  List<Task> _parseMarkdown(String markdown) {
    final tasks = <Task>[];
    final lines = markdown.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if ((trimmed.startsWith('- [ ]') || trimmed.startsWith('- ')) && !trimmed.startsWith('- [x]')) {
        final match = RegExp(r'^- \[?(x|\s)?\]?\s+(.*)$').firstMatch(trimmed);
        if (match != null) {
          final isDone = match.group(1) == 'x';
          final title = match.group(2)!.trim();
          tasks.add(
            Task(
              id: _uuid.v4(),
              title: title,
              status: isDone ? TaskStatus.done : TaskStatus.todo,
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    }
    return tasks;
  }

  @override
  void dispose() {
    for (final timer in _completionTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _autoScheduleDeadlines() async {
    final backlog = await _repo.getUnscheduled();
    final today = _normalizeDate(DateTime.now());

    for (final task in backlog) {
      if (task.deadline != null) {
        final normalizedDeadline = _normalizeDate(task.deadline!);
        // If deadline is today or in the past, schedule it for the deadline date
        if (normalizedDeadline.isBefore(today.add(const Duration(days: 1)))) {
          final updated = task.copyWith(scheduledDate: normalizedDeadline);
          await _repo.update(updated);
        }
      }
    }
  }

  Future<void> _propagateDeadline(Task task) async {
    if (!_settingsProvider.inheritParentDeadline || task.deadline == null || task.blockedById == null) return;

    final blocker = await _repo.getById(task.blockedById!);
    if (blocker == null) return;

    // If blocker has no deadline or a later deadline, update it to the child's deadline
    if (blocker.deadline == null || blocker.deadline!.isAfter(task.deadline!)) {
      final updatedBlocker = blocker.copyWith(deadline: task.deadline);
      await _repo.update(updatedBlocker);
      await _propagateDeadline(updatedBlocker);
    }
  }
}
