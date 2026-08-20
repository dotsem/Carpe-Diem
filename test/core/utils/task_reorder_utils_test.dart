import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('core', () {
    final now = DateTime.now();
    const settings = SettingsState({});

    final parent1 = Task(
      id: 'p1',
      title: 'Parent 1',
      createdAt: now,
      sortOrder: '0|i00000:',
    );
    final sub1 = Task(
      id: 's1',
      title: 'Subtask 1',
      parentId: 'p1',
      createdAt: now,
      sortOrder: '0|i00001:',
    );
    final sub2 = Task(
      id: 's2',
      title: 'Subtask 2',
      parentId: 'p1',
      createdAt: now,
      sortOrder: '0|i00002:',
    );
    final sub3 = Task(
      id: 's3',
      title: 'Subtask 3',
      parentId: 'p1',
      createdAt: now,
      sortOrder: '0|i00003:',
    );

    final parent2 = Task(
      id: 'p2',
      title: 'Parent 2',
      createdAt: now,
      sortOrder: '0|i00004:',
    );
    final sub21 = Task(
      id: 's21',
      title: 'Sub2 Task 1',
      parentId: 'p2',
      createdAt: now,
      sortOrder: '0|i00005:',
    );

    final allTasks = [parent1, sub1, sub2, sub3, parent2, sub21];

    test(
      'getTaskPosition correctly identifies subtask positions within its parent group',
      () {
        final posSub1 = TaskReorderUtils.getTaskPosition(
          task: sub1,
          tasks: allTasks,
          settings: settings,
        );
        expect(posSub1.isFirstInGroup, isTrue);
        expect(posSub1.isLastInGroup, isFalse);

        final posSub2 = TaskReorderUtils.getTaskPosition(
          task: sub2,
          tasks: allTasks,
          settings: settings,
        );
        expect(posSub2.isFirstInGroup, isFalse);
        expect(posSub2.isLastInGroup, isFalse);

        final posSub3 = TaskReorderUtils.getTaskPosition(
          task: sub3,
          tasks: allTasks,
          settings: settings,
        );
        expect(posSub3.isFirstInGroup, isFalse);
        expect(posSub3.isLastInGroup, isTrue);
      },
    );

    test('inSameGroup isolates subtasks by parentId', () {
      expect(TaskReorderUtils.inSameGroup(sub1, sub2, settings), isTrue);
      expect(TaskReorderUtils.inSameGroup(sub1, parent1, settings), isFalse);
      expect(TaskReorderUtils.inSameGroup(sub1, sub21, settings), isFalse);
    });
  });
}
