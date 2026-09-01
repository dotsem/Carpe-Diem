import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('core', () {
    final now = DateTime.now();
    const settings = SettingsState({});

    final parent1 = Task(
      id: 'p1',
      title: 'Parent 1',
      createdAt: now,
      sortOrder: 'a0',
    );
    final sub1 = Task(
      id: 's1',
      title: 'Subtask 1',
      parentId: 'p1',
      createdAt: now,
      sortOrder: 'a1',
    );
    final sub2 = Task(
      id: 's2',
      title: 'Subtask 2',
      parentId: 'p1',
      createdAt: now,
      sortOrder: 'a2',
    );
    final sub3 = Task(
      id: 's3',
      title: 'Subtask 3',
      parentId: 'p1',
      createdAt: now,
      sortOrder: 'a3',
    );

    final parent2 = Task(
      id: 'p2',
      title: 'Parent 2',
      createdAt: now,
      sortOrder: 'a4',
    );
    final sub21 = Task(
      id: 's21',
      title: 'Sub2 Task 1',
      parentId: 'p2',
      createdAt: now,
      sortOrder: 'a5',
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

    test('inSameGroup respects prioritizeDeadlines setting', () {
      final taskWithDeadline = Task(
        id: 'td1',
        title: 'With Deadline',
        deadline: DateTime(2026, 9, 1),
        createdAt: now,
      );
      final taskWithoutDeadline = Task(
        id: 'td2',
        title: 'Without Deadline',
        deadline: null,
        createdAt: now,
      );
      const withDeadlines = SettingsState({
        SettingsConstants.keyPrioritizeDeadlines: 'true',
      });
      const withoutDeadlines = SettingsState({
        SettingsConstants.keyPrioritizeDeadlines: 'false',
      });

      expect(
        TaskReorderUtils.inSameGroup(
          taskWithDeadline,
          taskWithoutDeadline,
          withDeadlines,
        ),
        isFalse,
      );
      expect(
        TaskReorderUtils.inSameGroup(
          taskWithDeadline,
          taskWithoutDeadline,
          withoutDeadlines,
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

        final topRank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.top,
          activeList: list,
        );
        expect(topRank.compareTo('a0'), lessThan(0));

        final bottomRank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.bottom,
          activeList: list,
        );
        expect(bottomRank.compareTo('a4'), greaterThan(0));

        final midRank = TaskReorderService.computeSortOrder(
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
          isUrgent: false,
          createdAt: now,
          sortOrder: 'a1',
        );
        final normal2 = Task(
          id: 'n2',
          title: 'N2',
          isUrgent: false,
          createdAt: now,
          sortOrder: 'a2',
        );
        final rawList = [urgentTask, normal1, normal2];

        final newTask = Task(
          id: 'new',
          title: 'New',
          isUrgent: false,
          createdAt: now,
        );

        final normalGroup = rawList
            .where((t) => TaskReorderUtils.inSameGroup(t, newTask, settings))
            .toList();

        expect(normalGroup.map((t) => t.id), equals(['n1', 'n2']));

        final topRank = TaskReorderService.computeSortOrder(
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
          scheduledDate: null,
          projectId: 'proj1',
          createdAt: now,
        );

        expect(TaskReorderUtils.inSameGroup(taskA, taskB, settings), isTrue);
        expect(TaskReorderUtils.inSameGroup(taskA, taskC, settings), isTrue);
        expect(TaskReorderUtils.inSameGroup(taskA, taskD, settings), isTrue);
      },
    );

    test(
      'computeSortOrder middle on single item list generates rank before item',
      () {
        final t1 = Task(id: '1', title: 'T1', createdAt: now, sortOrder: 'a0');
        final midRank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.middle,
          activeList: [t1],
        );
        expect(midRank.compareTo('a0'), lessThan(0));
      },
    );

    test('computeSortOrder handles fallback for empty sortOrder tasks', () {
      final emptyTask = Task(
        id: 'e',
        title: 'Empty',
        createdAt: now,
        sortOrder: '',
      );
      final topRank = TaskReorderService.computeSortOrder(
        placement: TaskPlacement.top,
        activeList: [emptyTask],
      );
      final bottomRank = TaskReorderService.computeSortOrder(
        placement: TaskPlacement.bottom,
        activeList: [emptyTask],
      );
      expect(topRank, equals('a0'));
      expect(bottomRank, equals('a0'));
    });
  });
}
