import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'task round-trips nullable fields through maps and handles status transitions',
    () {
      final date = DateTime(2026, 2, 3);
      final task = Task(
        id: 'task',
        title: 'Task',
        scheduledDate: date,
        deadline: date,
        updatedAt: date,
        completedAt: date,
        blockedById: 'blocker',
        blockerTitle: 'Blocker',
        blockerStatus: TaskStatus.todo,
        status: TaskStatus.done,
        createdAt: date,
      );
      final map = task.toMap()
        ..['blockerTitle'] = 'Blocker'
        ..['blockerStatus'] = TaskStatus.todo.index;
      expect(Task.fromMap(map).scheduledDate, date);
      expect(Task.fromMap(map).blockerStatus, TaskStatus.todo);
      expect(
        Task.fromMap(
          Task(id: 'plain', title: 'Plain', createdAt: date).toMap(),
        ).deadline,
        isNull,
      );
      expect(task.withStatus(TaskStatus.done).completedAt, date);
      expect(task.withStatus(TaskStatus.todo).completedAt, isNull);
      final blocker = Task(id: 'blocker', title: 'Blocker', createdAt: date);
      final dependent = Task(
        id: 'dependent',
        title: 'Dependent',
        blockedById: 'blocker',
        blockerStatus: TaskStatus.todo,
        createdAt: date,
      );
      expect(dependent.isBlocked, isTrue);
      expect(dependent.isBlockedBy(blocker), isTrue);
      expect(dependent.isBlockedBy(null), isFalse);
      expect(task.isBlockedBy(blocker), isFalse);
      expect(task.isOverdue, isFalse);
      expect(
        Task(
          id: 'scheduled-overdue',
          title: 'Overdue',
          scheduledDate: DateTime(2020),
          deadline: DateTime(2100),
          createdAt: date,
        ).isOverdue,
        isFalse,
      );
      expect(
        Task(
          id: 'deadline-overdue',
          title: 'Overdue',
          deadline: DateTime(2020),
          createdAt: date,
        ).isOverdue,
        isTrue,
      );
    },
  );
}
