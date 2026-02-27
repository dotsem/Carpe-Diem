import 'package:carpe_diem/data/models/task_layout.dart';
import 'package:carpe_diem/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_status.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/data/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo = TaskRepository();
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

    _tasks = await _repo.getByDate(_currentDate);
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

    _unscheduledTasks = await _repo.getUnscheduled();

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
    );
    await _repo.insert(task);
    await loadTasksForDate(_currentDate);
    await loadUnscheduledTasks();
  }

  Future<void> updateTaskStatus(Task task, TaskStatus status) async {
    final updated = task.copyWith(status: status);
    await _repo.update(updated);
    await _refreshAll();
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
    );
    await _repo.update(updated);
    await _refreshAll();
  }

  Future<void> toggleComplete(Task task) async {
    switch (task.status) {
      case TaskStatus.todo:
        await startTask(task);
        break;
      case TaskStatus.inProgress:
        await completeTask(task);
        break;
      case TaskStatus.done:
        await updateTaskStatus(task, TaskStatus.todo);
        break;
    }
  }

  Future<void> updateTask(Task task) async {
    await _repo.update(task);
    await _refreshAll();
  }

  Future<void> deleteTask(Task task) async {
    await _repo.delete(task.id);
    await _refreshAll();
  }

  Future<void> rescheduleOverdue(Task task, DateTime newDate) async {
    final updated = task.copyWith(scheduledDate: _normalizeDate(newDate));
    await _repo.update(updated);
    await _refreshAll();
  }

  Future<List<Task>> getTasksForProject(String projectId) async {
    return _repo.getByProject(projectId);
  }

  Future<List<Task>> getBacklog() async {
    return _repo.getUnscheduled();
  }

  Future<List<Task>> getTasksForLabel(String labelId) async {
    return _repo.getByLabel(labelId);
  }

  Future<void> _refreshAll() async {
    await loadTasksForDate(_currentDate, silent: true);
    await loadUnscheduledTasks(silent: true);
  }

  Future<void> scheduleTasksForDate(List<String> taskIds, DateTime date) async {
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
    await scheduleTasksForDate(taskIds, DateTime.now());
  }

  Future<void> scheduleTasksForTomorrow(List<String> taskIds) async {
    await scheduleTasksForDate(taskIds, DateTime.now().add(const Duration(days: 1)));
  }

  Future<void> importTasksFromMarkdown(String markdown, String? projectId) async {
    final tasks = _parseMarkdown(markdown);
    for (final task in tasks) {
      await _repo.insert(task.copyWith(projectId: projectId));
    }
    await _refreshAll();
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
}
