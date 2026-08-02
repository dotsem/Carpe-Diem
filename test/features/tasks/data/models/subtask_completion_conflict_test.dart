import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('tasks', () {
    test('SubtaskCompletionConflict holds parent and incomplete subtasks', () {
      final parent = createTestTask(id: 'p1', title: 'Parent');
      final sub1 = createTestTask(id: 's1', title: 'Sub 1', parentId: 'p1');
      final sub2 = createTestTask(id: 's2', title: 'Sub 2', parentId: 'p1');

      final conflict = SubtaskCompletionConflict(
        parentTask: parent,
        incompleteSubtasks: [sub1, sub2],
      );

      expect(conflict.parentTask.id, equals('p1'));
      expect(conflict.incompleteSubtasks.length, equals(2));
      expect(
        conflict.incompleteSubtasks.map((s) => s.id),
        containsAll(['s1', 's2']),
      );
    });
  });
}
