import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

extension TaskScheduleActions on TaskNotifier {
  Future<void> rescheduleOverdue(Task task, DateTime newDate) async {
    final cmd = schedulingService.buildScheduleCascadeCommand(
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
        ? await subtaskService.getAllSubtasksFromRepo(task.id)
        : <Task>[];
    final cmd = schedulingService.buildUnscheduleCascadeCommand(
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
        ? await subtaskService.getAllSubtasksFromRepo(task.id)
        : <Task>[];
    final cmd = schedulingService.buildScheduleCascadeCommand(
      task: task,
      date: date,
      cascadeChildren: cascadeChildren,
      subtasks: subtasks,
    );
    await executeCommand(cmd);
  }

  Future<void> scheduleTasksForDate(List<String> taskIds, DateTime date) async {
    final cmd = await schedulingService.buildBulkScheduleCommand(
      taskIds: taskIds,
      date: date,
      getTaskById: (id) async =>
          tasksState.getById(id) ?? await repo.getById(id),
    );
    if (cmd != null) await executeCommand(cmd);
  }

  Future<void> scheduleTasksForToday(List<String> taskIds) async {
    await scheduleTasksForDate(taskIds, DateTime.now());
  }

  Future<void> scheduleTasksForTomorrow(List<String> taskIds) async {
    await scheduleTasksForDate(
      taskIds,
      DateTime.now().add(const Duration(days: 1)),
    );
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
  }

  Future<void> scheduleTasksForNextWorkDay(List<String> taskIds) async {
    await scheduleTasksForDate(
      taskIds,
      DateTime.now().next(settings.firstDayOfWeek),
    );
  }

  Future<Task?> pickAndScheduleRandomTask(List<Task> availableTasks) async {
    final task = schedulingService.pickRandomTask(availableTasks);
    if (task != null) await scheduleTasksForToday([task.id]);
    return task;
  }
}
