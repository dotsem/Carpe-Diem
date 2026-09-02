import 'package:carpe_diem/core/utils/task_selection_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();

  group('TaskSelectionUtils', () {
    final parent = Task(id: 'p1', title: 'Parent', createdAt: now);
    final sub1 = Task(id: 's1', title: 'Sub 1', parentId: 'p1', createdAt: now);
    final sub2 = Task(id: 's2', title: 'Sub 2', parentId: 'p1', createdAt: now);
    final allTasks = [parent, sub1, sub2];

    test('getParentSelectionState returns false when no subtasks selected', () {
      final state = TaskSelectionUtils.getParentSelectionState(
        parentId: 'p1',
        subtasks: [sub1, sub2],
        selectedTaskIds: {},
      );
      expect(state, isFalse);
    });

    test('getParentSelectionState returns true when all subtasks selected', () {
      final state = TaskSelectionUtils.getParentSelectionState(
        parentId: 'p1',
        subtasks: [sub1, sub2],
        selectedTaskIds: {'s1', 's2'},
      );
      expect(state, isTrue);
    });

    test(
      'getParentSelectionState returns null when some subtasks selected',
      () {
        final state = TaskSelectionUtils.getParentSelectionState(
          parentId: 'p1',
          subtasks: [sub1, sub2],
          selectedTaskIds: {'s1'},
        );
        expect(state, isNull);
      },
    );

    test(
      'toggleSelection on unselected parent selects parent and all subtasks',
      () {
        final selected = TaskSelectionUtils.toggleSelection(
          task: parent,
          allTasks: allTasks,
          currentSelectedIds: {},
        );
        expect(selected, containsAll(['p1', 's1', 's2']));
      },
    );

    test(
      'toggleSelection on fully selected parent deselects parent and all subtasks',
      () {
        final selected = TaskSelectionUtils.toggleSelection(
          task: parent,
          allTasks: allTasks,
          currentSelectedIds: {'p1', 's1', 's2'},
        );
        expect(selected, isEmpty);
      },
    );

    test('toggleSelection on partially selected parent selects all', () {
      final selected = TaskSelectionUtils.toggleSelection(
        task: parent,
        allTasks: allTasks,
        currentSelectedIds: {'s1'},
      );
      expect(selected, containsAll(['p1', 's1', 's2']));
    });

    test('deselecting a subtask automatically deselects parent', () {
      final selected = TaskSelectionUtils.toggleSelection(
        task: sub1,
        allTasks: allTasks,
        currentSelectedIds: {'p1', 's1', 's2'},
      );
      expect(selected, contains('s2'));
      expect(selected, isNot(contains('s1')));
      expect(selected, isNot(contains('p1')));
    });

    test('selecting all subtasks one by one automatically selects parent', () {
      var selected = TaskSelectionUtils.toggleSelection(
        task: sub1,
        allTasks: allTasks,
        currentSelectedIds: {},
      );
      expect(selected, equals({'s1'}));

      selected = TaskSelectionUtils.toggleSelection(
        task: sub2,
        allTasks: allTasks,
        currentSelectedIds: selected,
      );
      expect(selected, containsAll(['p1', 's1', 's2']));
    });
  });
}
