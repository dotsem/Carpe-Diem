part of 'task_provider.dart';

extension TaskNotifierExtension on TaskNotifier {
  Future<void> cleanupHistory() async {
    final settings = ref.read(settingsProvider);
    final days = settings.historyRetention;
    if (days > 0) {
      final deletedCount = await _repo.cleanupHistory(days);
      if (deletedCount > 0) {
        await _refreshAll();
      }
    }
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
    final settings = ref.read(settingsProvider);
    DateTime? projectDeadline;
    bool shouldInheritDeadline = false;
    if (updateProjectId && projectId != null && settings.inheritProjectDeadline) {
      final project = await _projectRepo.getById(projectId);
      if (project?.deadline != null) {
        projectDeadline = project!.deadline;
        shouldInheritDeadline = true;
      }
    }

    for (final id in taskIds) {
      Task? task;
      try {
        task = tasksState.tasks.firstWhere(
          (t) => t.id == id,
          orElse: () => tasksState.overdueTasks.firstWhere(
            (t) => t.id == id,
            orElse: () => tasksState.unscheduledTasks.firstWhere((t) => t.id == id),
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
        if (settings.inheritParentDeadline && updated.deadline != null) {
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

  Future<void> _scheduleTasksForDate(List<String> taskIds, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    for (final id in taskIds) {
      Task? task;
      try {
        task = tasksState.tasks.firstWhere(
          (t) => t.id == id,
          orElse: () => tasksState.overdueTasks.firstWhere(
            (t) => t.id == id,
            orElse: () => tasksState.unscheduledTasks.firstWhere((t) => t.id == id),
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
    final settings = ref.read(settingsProvider);
    DateTime nextStartOfWeek = DateTime.now().next(settings.firstDayOfWeek);
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
    return _historyRepo.getCompletedInRange(start, end, limit: limit, offset: offset, filter: filter);
  }

  Future<DateTime> getFirstTaskDate() async {
    final firstCompleted = await _historyRepo.getFirstCompletedDate();
    if (firstCompleted != null) return firstCompleted;
    return DateTime.now();
  }

  Future<HistoryOverview> getHistoryOverview(DateTime start, DateTime end, {TaskFilter? filter}) async {
    return _historyRepo.getHistoryOverview(start, end, filter: filter);
  }

  Future<void> importTasksFromMarkdown(String markdown, String? projectId) async {
    final tasks = TaskMarkdownParser.parseMarkdown(markdown);
    final settings = ref.read(settingsProvider);
    DateTime? projectDeadline;
    if (projectId != null && settings.inheritProjectDeadline) {
      final project = await _projectRepo.getById(projectId);
      projectDeadline = project?.deadline;
    }

    for (final task in tasks) {
      await _repo.insert(task.copyWith(projectId: projectId, deadline: projectDeadline));
    }
    await _refreshAll();
    ToastUtils.showSuccess('Imported ${tasks.length} tasks from markdown');
  }

  Future<void> _autoScheduleDeadlines() async {
    final backlog = await _repo.getUnscheduled();
    final today = _normalizeDate(DateTime.now());

    for (final task in backlog) {
      if (task.deadline != null) {
        final normalizedDeadline = _normalizeDate(task.deadline!);
        if (normalizedDeadline.isBefore(today.add(const Duration(days: 1)))) {
          final updated = task.copyWith(scheduledDate: normalizedDeadline);
          await _repo.update(updated);
        }
      }
    }
  }

  Future<void> _propagateDeadline(Task task, [Set<String>? visited]) async {
    final settings = ref.read(settingsProvider);
    if (!settings.inheritParentDeadline || task.deadline == null || task.blockedById == null) return;

    final localVisited = visited ?? <String>{};
    if (localVisited.contains(task.id)) return;
    localVisited.add(task.id);

    final blocker = await _repo.getById(task.blockedById!);
    if (blocker == null) return;

    if (blocker.deadline == null || blocker.deadline!.isAfter(task.deadline!)) {
      final updatedBlocker = blocker.copyWith(deadline: task.deadline);
      await _repo.update(updatedBlocker);
      await _propagateDeadline(updatedBlocker, localVisited);
    }
  }
}
