import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_scheduling_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:intl/intl.dart';

extension TaskScheduleActions on TaskNotifier {
  Future<void> rescheduleOverdue(Task task, DateTime newDate) async {
    final cmd = TaskSchedulingService.buildScheduleCascadeCommand(
      repo: repo,
      task: task,
      date: newDate,
      cascadeChildren: false,
      subtasks: const [],
    );
    await executeCommand(cmd);
  }

  Future<void> unScheduleTask(
    Task task, {
    bool resetStatus = false,
    bool unscheduleChildren = false,
  }) async {
    final subtasks = unscheduleChildren
        ? await SubtaskService.getAllSubtasksFromRepo(
            repo: repo,
            parentId: task.id,
          )
        : <Task>[];
    final cmd = TaskSchedulingService.buildUnscheduleCascadeCommand(
      repo: repo,
      task: task,
      resetStatus: resetStatus,
      unscheduleChildren: unscheduleChildren,
      subtasks: subtasks,
    );
    await executeCommand(cmd);
  }

  Future<void> scheduleTaskWithCascade(
    Task task,
    DateTime date, {
    required bool cascadeChildren,
  }) async {
    final subtasks = cascadeChildren
        ? await SubtaskService.getAllSubtasksFromRepo(
            repo: repo,
            parentId: task.id,
          )
        : <Task>[];
    final cmd = TaskSchedulingService.buildScheduleCascadeCommand(
      repo: repo,
      task: task,
      date: date,
      cascadeChildren: cascadeChildren,
      subtasks: subtasks,
    );
    await executeCommand(cmd);
  }

  Future<void> scheduleTasksForDate(List<String> taskIds, DateTime date) async {
    final cmd = await TaskSchedulingService.buildBulkScheduleCommand(
      repo: repo,
      taskIds: taskIds,
      date: date,
      getTaskById: (id) async =>
          tasksState.getById(id) ?? await repo.getById(id),
    );
    if (cmd != null) await executeCommand(cmd);
  }

  Future<void> scheduleTasksForToday(List<String> taskIds) async {
    await scheduleTasksForDate(taskIds, DateTime.now());
    ToastUtils.showSuccess('Tasks scheduled for today');
  }

  Future<void> scheduleTasksForTomorrow(List<String> taskIds) async {
    await scheduleTasksForDate(
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
    final normalized = nextDay.normalize;
    await scheduleTasksForDate(taskIds, normalized);
    ToastUtils.showSuccess(
      'Tasks scheduled for ${DateFormat('MMM d').format(normalized)}',
    );
  }

  Future<void> scheduleTasksForNextWorkDay(List<String> taskIds) async {
    final settings = ref.read(settingsProvider);
    await scheduleTasksForDate(
      taskIds,
      DateTime.now().next(settings.firstDayOfWeek),
    );
    ToastUtils.showSuccess('Tasks scheduled for next week');
  }

  Future<Task?> pickAndScheduleRandomTask(List<Task> availableTasks) async {
    final task = TaskSchedulingService.pickRandomTask(availableTasks);
    if (task != null) await scheduleTasksForToday([task.id]);
    return task;
  }
}
