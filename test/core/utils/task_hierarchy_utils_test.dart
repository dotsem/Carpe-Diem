import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

void main() {
  group('core', () {
    final now = DateTime.now();

    Task createTask({
      required String id,
      String? blockedById,
      TaskStatus status = TaskStatus.todo,
      String title = '',
    }) {
      return Task(
        id: id,
        title: title.isEmpty ? 'Task $id' : title,
        createdAt: now,
        status: status,
        blockedById: blockedById,
      );
    }

    test('buildHierarchy with empty list returns empty list', () {
      final result = TaskHierarchyUtils.buildHierarchy([]);
      expect(result, isEmpty);
    });

    test('buildHierarchy flats standard list with no relationships', () {
      final tasks = [createTask(id: '1'), createTask(id: '2')];

      final result = TaskHierarchyUtils.buildHierarchy(tasks);

      expect(result.length, 2);
      expect(result[0], isA<TaskNode>());
      expect((result[0] as TaskNode).task.id, '1');
      expect(result[0].depth, 0);

      expect(result[1], isA<TaskNode>());
      expect((result[1] as TaskNode).task.id, '2');
      expect(result[1].depth, 0);
    });

    test(
      'buildHierarchy with internal blocker indents blocked task under blocker',
      () {
        // 1 <- 2 (2 is blocked by 1)
        final tasks = [
          createTask(id: '2', blockedById: '1'),
          createTask(id: '1'),
        ];

        final result = TaskHierarchyUtils.buildHierarchy(tasks);

        expect(result.length, 2);
        expect((result[0] as TaskNode).task.id, '1');
        expect(result[0].depth, 0);

        expect((result[1] as TaskNode).task.id, '2');
        expect(result[1].depth, 1);
        expect((result[1] as TaskNode).isBundledUnderParent, isFalse);
      },
    );

    test(
      'buildHierarchy with external incomplete blocker builds BlockerIndicatorNode',
      () {
        final tasks = [createTask(id: '2', blockedById: '1')];
        final allTasks = {
          '1': createTask(
            id: '1',
            status: TaskStatus.todo,
            title: 'Blocker Title',
          ),
          '2': createTask(id: '2', blockedById: '1'),
        };

        final result = TaskHierarchyUtils.buildHierarchy(
          tasks,
          allTasks: allTasks,
        );

        expect(result.length, 2);
        expect(result[0], isA<BlockerIndicatorNode>());
        final indicator = result[0] as BlockerIndicatorNode;
        expect(indicator.blockerId, '1');
        expect(indicator.blockerTitle, 'Blocker Title');
        expect(indicator.blockedTaskId, '2');
        expect(indicator.depth, 0);

        expect(result[1], isA<TaskNode>());
        expect((result[1] as TaskNode).task.id, '2');
        expect(result[1].depth, 1);
      },
    );

    test('buildHierarchy ignores completed external blocker', () {
      final tasks = [createTask(id: '2', blockedById: '1')];
      final allTasks = {
        '1': createTask(id: '1', status: TaskStatus.done),
        '2': createTask(id: '2', blockedById: '1'),
      };

      final result = TaskHierarchyUtils.buildHierarchy(
        tasks,
        allTasks: allTasks,
      );

      // Blocker is done, so it should not render as a BlockerIndicatorNode
      expect(result.length, 1);
      expect(result[0], isA<TaskNode>());
      expect((result[0] as TaskNode).task.id, '2');
      expect(result[0].depth, 0);
    });

    test(
      'buildHierarchy handles cycle parent relationships gracefully by emitting them starting from the first node as root',
      () {
        final tasks = [
          Task(id: '1', title: '1', createdAt: now, parentId: '2'),
          Task(id: '2', title: '2', createdAt: now, parentId: '1'),
        ];

        final result = TaskHierarchyUtils.buildHierarchy(tasks);

        expect(result.length, 2);
        expect((result[0] as TaskNode).task.id, '1');
        expect(result[0].depth, 0);

        expect((result[1] as TaskNode).task.id, '2');
        expect(result[1].depth, 1);
      },
    );

    test('buildHierarchy nests subtasks under parent using parentId', () {
      final parent = Task(id: 'parent_1', title: 'Parent Task', createdAt: now);
      final subtask = Task(
        id: 'sub_1',
        title: 'Subtask 1',
        parentId: 'parent_1',
        createdAt: now,
      );

      final result = TaskHierarchyUtils.buildHierarchy([subtask, parent]);

      expect(result.length, 2);
      expect((result[0] as TaskNode).task.id, 'parent_1');
      expect(result[0].depth, 0);

      expect((result[1] as TaskNode).task.id, 'sub_1');
      expect(result[1].depth, 1);
    });

    test(
      'buildHierarchy renders subtask at depth 0 when parent is not present in category',
      () {
        final subtask = Task(
          id: 'sub_1',
          title: 'Subtask 1',
          parentId: 'completed_parent',
          createdAt: now,
        );

        final result = TaskHierarchyUtils.buildHierarchy([subtask]);

        expect(result.length, 1);
        expect((result[0] as TaskNode).task.id, 'sub_1');
        expect(result[0].depth, 0);
      },
    );

    test(
      'buildHierarchy with asParentContainers emits ParentContainerNode with urgent flag',
      () {
        final parent = Task(
          id: 'parent_1',
          title: 'Parent',
          createdAt: now,
          isUrgent: false,
        );
        final urgentSubtask = Task(
          id: 'sub_1',
          title: 'Urgent Subtask',
          parentId: 'parent_1',
          createdAt: now,
          isUrgent: true,
        );

        final result = TaskHierarchyUtils.buildHierarchy([
          urgentSubtask,
          parent,
        ], asParentContainers: true);

        expect(result.length, 2);
        expect(result[0], isA<ParentContainerNode>());
        final container = result[0] as ParentContainerNode;
        expect(container.task.id, 'parent_1');
        expect(container.totalSubtasks, 1);
        expect(container.hasUrgentChild, isTrue);

        expect(result[1], isA<TaskNode>());
        expect((result[1] as TaskNode).task.id, 'sub_1');
        expect(result[1].depth, 1);
      },
    );

    test(
      'buildHierarchy with asParentContainers updates urgent flag when subtask is non-urgent',
      () {
        final parent = Task(
          id: 'parent_1',
          title: 'Parent',
          createdAt: now,
          isUrgent: false,
        );
        final normalSubtask = Task(
          id: 'sub_1',
          title: 'Normal Subtask',
          parentId: 'parent_1',
          createdAt: now,
          isUrgent: false,
        );

        final result = TaskHierarchyUtils.buildHierarchy([
          normalSubtask,
          parent,
        ], asParentContainers: true);

        expect(result.length, 2);
        expect(result[0], isA<ParentContainerNode>());
        final container = result[0] as ParentContainerNode;
        expect(container.hasUrgentChild, isFalse);
      },
    );

    test(
      'buildHierarchy with asParentContainers does not treat blockers as parent containers',
      () {
        final blocker = Task(
          id: 'blocker_1',
          title: 'Blocker Task',
          createdAt: now,
          isUrgent: false,
        );
        final blockedTask = Task(
          id: 'blocked_1',
          title: 'Blocked Task',
          blockedById: 'blocker_1',
          createdAt: now,
          isUrgent: true,
        );

        final result = TaskHierarchyUtils.buildHierarchy([
          blockedTask,
          blocker,
        ], asParentContainers: true);

        expect(result.length, 2);
        expect(result[0], isA<TaskNode>());
        expect((result[0] as TaskNode).task.id, 'blocker_1');
        expect(result[0].depth, 0);

        expect(result[1], isA<TaskNode>());
        expect((result[1] as TaskNode).task.id, 'blocked_1');
        expect(result[1].depth, 1);
      },
    );
  });
}
