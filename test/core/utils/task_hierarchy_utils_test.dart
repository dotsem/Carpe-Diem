import 'package:flutter_test/flutter_test.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';

void main() {
  group('TaskHierarchyUtils', () {
    final now = DateTime.now();

    Task createTask({required String id, String? blockedById, TaskStatus status = TaskStatus.todo, String title = ''}) {
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
      final tasks = [
        createTask(id: '1'),
        createTask(id: '2'),
      ];

      final result = TaskHierarchyUtils.buildHierarchy(tasks);

      expect(result.length, 2);
      expect(result[0], isA<TaskNode>());
      expect((result[0] as TaskNode).task.id, '1');
      expect(result[0].depth, 0);

      expect(result[1], isA<TaskNode>());
      expect((result[1] as TaskNode).task.id, '2');
      expect(result[1].depth, 0);
    });

    test('buildHierarchy nesting builds correct internal parent-child tree hierarchy', () {
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
    });

    test('buildHierarchy with external incomplete blocker builds BlockerIndicatorNode', () {
      final tasks = [
        createTask(id: '2', blockedById: '1'),
      ];
      final allTasks = {
        '1': createTask(id: '1', status: TaskStatus.todo, title: 'Blocker Title'),
        '2': createTask(id: '2', blockedById: '1'),
      };

      final result = TaskHierarchyUtils.buildHierarchy(tasks, allTasks: allTasks);

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
    });

    test('buildHierarchy ignores completed external blocker', () {
      final tasks = [
        createTask(id: '2', blockedById: '1'),
      ];
      final allTasks = {
        '1': createTask(id: '1', status: TaskStatus.done),
        '2': createTask(id: '2', blockedById: '1'),
      };

      final result = TaskHierarchyUtils.buildHierarchy(tasks, allTasks: allTasks);

      // Blocker is done, so it should not render as a BlockerIndicatorNode
      expect(result.length, 1);
      expect(result[0], isA<TaskNode>());
      expect((result[0] as TaskNode).task.id, '2');
      expect(result[0].depth, 0);
    });

    test('buildHierarchy handles cycle dependencies gracefully without infinite loop', () {
      final tasks = [
        createTask(id: '1', blockedById: '2'),
        createTask(id: '2', blockedById: '1'),
      ];

      final result = TaskHierarchyUtils.buildHierarchy(tasks);

      // It should still process them without throwing/hanging
      expect(result, isNotEmpty);
      expect(result.length, lessThanOrEqualTo(2));
    });
  });
}
