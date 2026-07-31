import 'package:carpe_diem/features/tasks/data/models/task.dart';

class SubtaskCompletionConflict {
  final Task parentTask;
  final List<Task> incompleteSubtasks;

  const SubtaskCompletionConflict({
    required this.parentTask,
    required this.incompleteSubtasks,
  });
}
