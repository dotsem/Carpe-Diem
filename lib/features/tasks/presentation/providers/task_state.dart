import 'package:carpe_diem/features/tasks/data/models/task.dart';

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
