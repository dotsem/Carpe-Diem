import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state_reorder_extension.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskStateReorderExtension', () {
    const defaultSettings = SettingsState({});

    group('applyOptimisticTask ordering', () {
      test('returns currentList untouched when task is not present', () {
        final list = [createTestTask()];
        final notInList = createTestTask(id: 't2');
        final result = TaskState(
          currentDate: DateTime(2026),
          tasks: list,
        ).applyOptimisticTask(notInList, defaultSettings.taskPrefs).tasks;
        expect(result, equals(list));
      });

      test('sorts urgent tasks to the front', () {
        final normal = createTestTask();
        final urgent = createTestTask(id: 't2');
        final updatedUrgent = urgent.copyWith(isUrgent: true);
        final result = TaskState(
          currentDate: DateTime(2026),
          tasks: [normal, urgent],
        ).applyOptimisticTask(updatedUrgent, defaultSettings.taskPrefs).tasks;

        expect(result.first.id, equals('t2'));
      });

      test('respects sortOrder string lexicographical order', () {
        final t1 = createTestTask().copyWith(sortOrder: '0|i00005:');
        final t2 = createTestTask(id: 't2').copyWith(sortOrder: '0|i00010:');
        final updatedT2 = t2.copyWith(sortOrder: '0|i00001:');
        final result = TaskState(
          currentDate: DateTime(2026),
          tasks: [t1, t2],
        ).applyOptimisticTask(updatedT2, defaultSettings.taskPrefs).tasks;

        expect(result.map((t) => t.id), equals(['t2', 't1']));
      });
    });

    group('applyOptimisticTask and applyBulkOptimisticReorder', () {
      test('updates matching task in TaskState collections', () {
        final t1 = createTestTask().copyWith(sortOrder: '0|i00010:');
        final state = TaskState(
          currentDate: DateTime(2026),
          tasks: [t1],
          overdueTasks: [t1],
          unscheduledTasks: [t1],
        );
        final updatedT1 = t1.copyWith(sortOrder: '0|i00001:');
        final newState = state.applyOptimisticTask(
          updatedT1,
          defaultSettings.taskPrefs,
        );

        expect(newState.tasks.first.sortOrder, equals('0|i00001:'));
        expect(newState.overdueTasks.first.sortOrder, equals('0|i00001:'));
        expect(newState.unscheduledTasks.first.sortOrder, equals('0|i00001:'));
      });

      test('applies bulk optimistic reorders across state collections', () {
        final t1 = createTestTask().copyWith(sortOrder: '0|i00010:');
        final t2 = createTestTask(id: 't2').copyWith(sortOrder: '0|i00020:');
        final state = TaskState(currentDate: DateTime(2026), tasks: [t1, t2]);

        final newState = state.applyBulkOptimisticReorder({
          't1': '0|i00030:',
        }, defaultSettings.taskPrefs);

        expect(newState.tasks.map((t) => t.id), equals(['t2', 't1']));
      });
    });

    test('applyBulkOptimisticReorderList reorders by planSortOrder', () {
      final first = createTestTask().copyWith(planSortOrder: 'a');
      final second = createTestTask(id: 't2').copyWith(planSortOrder: 'b');

      final result = TaskStateReorderExtension.applyBulkOptimisticReorderList(
        [first, second],
        {'t1': 'c'},
        defaultSettings.taskPrefs,
        isPlanOrder: true,
      );

      expect(result.map((t) => t.id), ['t2', 't1']);
      expect(result.last.sortOrder, first.sortOrder);
    });
  });
}
