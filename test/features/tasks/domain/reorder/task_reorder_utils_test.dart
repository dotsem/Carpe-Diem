import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/actions/task_reorder_actions.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

class MockTaskNotifier extends Mock implements TaskNotifier {}

void main() {
  setUpAll(() => registerFallbackValue(<String, String>{}));
  group('core', () {
    final now = DateTime.now();
    const settings = SettingsState({});
    final reorderService = TaskReorderService(
      MockTaskRepository(),
      () => settings.taskPrefs,
    );

    Task t(
      String id,
      String title, {
      String? parentId,
      String sortOrder = '',
    }) => Task(
      id: id,
      title: title,
      parentId: parentId,
      createdAt: now,
      sortOrder: sortOrder,
    );

    final parent1 = t('p1', 'Parent 1', sortOrder: 'a0');
    final sub1 = t('s1', 'Subtask 1', parentId: 'p1', sortOrder: 'a1');
    final sub2 = t('s2', 'Subtask 2', parentId: 'p1', sortOrder: 'a2');
    final sub3 = t('s3', 'Subtask 3', parentId: 'p1', sortOrder: 'a3');
    final parent2 = t('p2', 'Parent 2', sortOrder: 'a4');
    final sub21 = t('s21', 'Sub2 Task 1', parentId: 'p2', sortOrder: 'a5');

    final allTasks = [parent1, sub1, sub2, sub3, parent2, sub21];

    test(
      'getTaskPosition correctly identifies subtask positions within its parent group',
      () {
        final posSub1 = TaskReorderUtils.getTaskPosition(
          task: sub1,
          tasks: allTasks,
          settings: settings.taskPrefs,
        );
        expect(posSub1.isFirstInGroup, isTrue);
        expect(posSub1.isLastInGroup, isFalse);

        final posSub2 = TaskReorderUtils.getTaskPosition(
          task: sub2,
          tasks: allTasks,
          settings: settings.taskPrefs,
        );
        expect(posSub2.isFirstInGroup, isFalse);
        expect(posSub2.isLastInGroup, isFalse);

        final posSub3 = TaskReorderUtils.getTaskPosition(
          task: sub3,
          tasks: allTasks,
          settings: settings.taskPrefs,
        );
        expect(posSub3.isFirstInGroup, isFalse);
        expect(posSub3.isLastInGroup, isTrue);
      },
    );

    test('inSameGroup isolates subtasks by parentId', () {
      expect(
        TaskReorderEngine.inSameGroup(sub1, sub2, settings.taskPrefs),
        isTrue,
      );
      expect(
        TaskReorderEngine.inSameGroup(sub1, parent1, settings.taskPrefs),
        isFalse,
      );
      expect(
        TaskReorderEngine.inSameGroup(sub1, sub21, settings.taskPrefs),
        isFalse,
      );
    });

    test(
      'inSameGroup with isPlanView treats orphan subtasks as root group',
      () {
        final orphan = Task(
          id: 'orphan',
          parentId: 'missing_parent',
          title: 'Orphan',
          createdAt: now,
        );
        final root = Task(id: 'root', title: 'Root', createdAt: now);
        final nodes = [TaskNode(orphan, 0), TaskNode(root, 0)];

        expect(
          TaskReorderEngine.inSameGroup(
            orphan,
            root,
            settings.taskPrefs,
            nodes: nodes,
            isPlanView: true,
          ),
          isTrue,
        );
        expect(
          TaskReorderEngine.inSameGroup(
            orphan,
            root,
            settings.taskPrefs,
            nodes: nodes,
          ),
          isFalse,
        );
      },
    );

    test('inSameGroup respects prioritizeDeadlines setting', () {
      final taskWithDeadline = Task(
        id: 'td1',
        title: 'With Deadline',
        deadline: DateTime(2026, 9),
        createdAt: now,
      );
      final taskWithoutDeadline = Task(
        id: 'td2',
        title: 'Without Deadline',
        createdAt: now,
      );
      const withDeadlines = SettingsState({
        SettingsConstants.keyPrioritizeDeadlines: 'true',
      });
      const withoutDeadlines = SettingsState({
        SettingsConstants.keyPrioritizeDeadlines: 'false',
      });

      expect(
        TaskReorderEngine.inSameGroup(
          taskWithDeadline,
          taskWithoutDeadline,
          withDeadlines.taskPrefs,
        ),
        isFalse,
      );
      expect(
        TaskReorderEngine.inSameGroup(
          taskWithDeadline,
          taskWithoutDeadline,
          withoutDeadlines.taskPrefs,
        ),
        isTrue,
      );
    });

    test(
      'computeSortOrder correctly computes top, middle, and bottom ranks',
      () {
        final t1 = Task(id: '1', title: 'T1', createdAt: now, sortOrder: 'a0');
        final t2 = Task(id: '2', title: 'T2', createdAt: now, sortOrder: 'a2');
        final t3 = Task(id: '3', title: 'T3', createdAt: now, sortOrder: 'a4');
        final list = [t1, t2, t3];

        final topRank = reorderService.computeSortOrder(
          placement: TaskPlacement.top,
          activeList: list,
        );
        expect(topRank.compareTo('a0'), lessThan(0));

        final bottomRank = reorderService.computeSortOrder(
          placement: TaskPlacement.bottom,
          activeList: list,
        );
        expect(bottomRank.compareTo('a4'), greaterThan(0));

        final midRank = reorderService.computeSortOrder(
          placement: TaskPlacement.middle,
          activeList: list,
        );
        expect(midRank.compareTo('a0'), greaterThan(0));
        expect(midRank.compareTo('a4'), lessThan(0));
      },
    );

    test(
      'group-filtered placement calculates rank only relative to tasks in the same group',
      () {
        final urgentTask = Task(
          id: 'u1',
          title: 'Urgent',
          isUrgent: true,
          createdAt: now,
          sortOrder: 'a0',
        );
        final normal1 = Task(
          id: 'n1',
          title: 'N1',
          createdAt: now,
          sortOrder: 'a1',
        );
        final normal2 = Task(
          id: 'n2',
          title: 'N2',
          createdAt: now,
          sortOrder: 'a2',
        );
        final rawList = [urgentTask, normal1, normal2];

        final newTask = Task(id: 'new', title: 'New', createdAt: now);

        final normalGroup = rawList
            .where(
              (t) =>
                  TaskReorderEngine.inSameGroup(t, newTask, settings.taskPrefs),
            )
            .toList();

        expect(normalGroup.map((t) => t.id), equals(['n1', 'n2']));

        final topRank = reorderService.computeSortOrder(
          placement: TaskPlacement.top,
          activeList: normalGroup,
        );
        expect(topRank.compareTo(normal1.sortOrder), lessThan(0));
      },
    );

    test(
      'inSameGroup allows cross-scheduledDate and cross-project reordering',
      () {
        final taskA = Task(
          id: 'a',
          title: 'A',
          scheduledDate: now,
          projectId: 'proj1',
          createdAt: now,
        );
        final taskB = Task(
          id: 'b',
          title: 'B',
          scheduledDate: now.add(const Duration(days: 1)),
          projectId: 'proj1',
          createdAt: now,
        );
        final taskC = Task(
          id: 'c',
          title: 'C',
          scheduledDate: now,
          projectId: 'proj2',
          createdAt: now,
        );
        final taskD = Task(
          id: 'd',
          title: 'D',
          projectId: 'proj1',
          createdAt: now,
        );

        expect(
          TaskReorderEngine.inSameGroup(taskA, taskB, settings.taskPrefs),
          isTrue,
        );
        expect(
          TaskReorderEngine.inSameGroup(taskA, taskC, settings.taskPrefs),
          isTrue,
        );
        expect(
          TaskReorderEngine.inSameGroup(taskA, taskD, settings.taskPrefs),
          isTrue,
        );
      },
    );

    test(
      'computeSortOrder middle on single item list generates rank before item',
      () {
        final t1 = Task(id: '1', title: 'T1', createdAt: now, sortOrder: 'a0');
        final midRank = reorderService.computeSortOrder(
          placement: TaskPlacement.middle,
          activeList: [t1],
        );
        expect(midRank.compareTo('a0'), lessThan(0));
      },
    );

    test('computeSortOrder handles fallback for empty sortOrder tasks', () {
      final emptyTask = Task(id: 'e', title: 'Empty', createdAt: now);
      final topRank = reorderService.computeSortOrder(
        placement: TaskPlacement.top,
        activeList: [emptyTask],
      );
      final bottomRank = reorderService.computeSortOrder(
        placement: TaskPlacement.bottom,
        activeList: [emptyTask],
      );
      expect(topRank, equals('a0'));
      expect(bottomRank, equals('a0'));
    });

    test('getTaskPosition can group without settings', () {
      final first = t('first', 'First', sortOrder: 'a0');
      final last = t('last', 'Last', sortOrder: 'a1');

      final position = TaskReorderUtils.getTaskPosition(
        task: last,
        tasks: [first, last],
      );

      expect(position.indexInList, 1);
      expect(position.isLastInGroup, isTrue);
    });

    test('moveToTop and moveToBottom reorder within the same group', () {
      final notifier = MockTaskNotifier();
      final first = t('first', 'First', sortOrder: 'a0');
      final middle = t('middle', 'Middle', sortOrder: 'a1');
      final last = t('last', 'Last', sortOrder: 'a2');
      when(
        () => notifier.reorderTask(
          middle,
          any(),
          isPlanOrder: any(named: 'isPlanOrder'),
        ),
      ).thenAnswer((_) async {});

      TaskReorderActions.moveToTop(notifier, middle, [
        first,
        middle,
        last,
      ], settings.taskPrefs);
      final topRank =
          verify(
                () => notifier.reorderTask(middle, captureAny()),
              ).captured.single
              as String;
      expect(topRank.compareTo(first.sortOrder), lessThan(0));

      TaskReorderActions.moveToBottom(
        notifier,
        middle,
        [first, middle, last],
        settings.taskPrefs,
        isPlanView: true,
      );
      final bottomRank =
          verify(
                () => notifier.reorderTask(
                  middle,
                  captureAny(),
                  isPlanOrder: true,
                ),
              ).captured.single
              as String;
      expect(bottomRank.compareTo(last.sortOrder), greaterThan(0));
    });

    test('moveToTop and moveToBottom do nothing at an existing edge', () {
      final notifier = MockTaskNotifier();
      final first = t('first', 'First', sortOrder: 'a0');
      final last = t('last', 'Last', sortOrder: 'a1');

      TaskReorderActions.moveToTop(notifier, first, [
        first,
        last,
      ], settings.taskPrefs);
      TaskReorderActions.moveToBottom(notifier, last, [
        first,
        last,
      ], settings.taskPrefs);

      verifyNoMoreInteractions(notifier);
    });

    test(
      'dispatches multi reorder through a notifier when no callback is supplied',
      () {
        final notifier = MockTaskNotifier();
        final first = t('first', 'First', sortOrder: 'a0');
        final middle = t('middle', 'Middle', sortOrder: 'a1');
        final last = t('last', 'Last', sortOrder: 'a2');
        when(() => notifier.bulkReorderTasks(any())).thenAnswer((_) async {});

        final result = TaskReorderActions.dispatchReorder(
          nodes: [TaskNode(first, 0), TaskNode(middle, 0), TaskNode(last, 0)],
          draggedTask: middle,
          newIndex: 0,
          prefs: settings.taskPrefs,
          selectedTaskIds: const {'middle', 'last'},
          notifier: notifier,
        );

        expect(result, isTrue);
        verify(() => notifier.bulkReorderTasks(any())).called(1);
      },
    );
  });
}
