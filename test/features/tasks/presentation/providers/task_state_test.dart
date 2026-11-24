import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TaskState finds tasks in every collection and keeps them on copyWith',
    () {
      final date = DateTime(2026);
      Task task(String id) => Task(id: id, title: id, createdAt: date);
      final state = TaskState(
        currentDate: date,
        tasks: [task('today')],
        overdueTasks: [task('overdue')],
        unscheduledTasks: [task('backlog')],
      );
      expect(state.getById('today')?.id, 'today');
      expect(state.getById('overdue')?.id, 'overdue');
      expect(state.getById('backlog')?.id, 'backlog');
      expect(state.getById('missing'), isNull);
      expect(state.copyWith().allTasks, hasLength(3));
    },
  );
}
