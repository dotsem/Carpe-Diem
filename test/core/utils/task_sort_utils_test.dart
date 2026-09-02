import 'package:carpe_diem/core/utils/task_sort_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskSortUtils', () {
    final now = DateTime.now();

    test('sorts urgent tasks before normal tasks', () {
      final normal = Task(
        id: '1',
        title: 'Normal',
        isUrgent: false,
        createdAt: now,
      );
      final urgent = Task(
        id: '2',
        title: 'Urgent',
        isUrgent: true,
        createdAt: now,
      );

      final tasks = [normal, urgent];
      TaskSortUtils.sortTasks(tasks, const SettingsState({}));

      expect(tasks.first.id, '2');
      expect(tasks.last.id, '1');
    });

    test('sorts by sortOrder when urgency is equal', () {
      final taskA = Task(
        id: '1',
        title: 'Task A',
        sortOrder: 'b',
        createdAt: now,
      );
      final taskB = Task(
        id: '2',
        title: 'Task B',
        sortOrder: 'a',
        createdAt: now,
      );

      final tasks = [taskA, taskB];
      TaskSortUtils.sortTasks(tasks, const SettingsState({}));

      expect(tasks.first.id, '2');
      expect(tasks.last.id, '1');
    });
  });
}
