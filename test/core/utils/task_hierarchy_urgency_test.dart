import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskHierarchyUtils urgency elevation', () {
    final now = DateTime.now();

    test(
      'buildHierarchy emits non-urgent parent with incomplete urgent subtask before non-urgent root task',
      () {
        final parent = Task(
          id: 'p1',
          title: 'Parent',
          createdAt: now,
          isUrgent: false,
          sortOrder: 'b0',
        );
        final urgentSub = Task(
          id: 's1',
          title: 'Urgent Subtask',
          parentId: 'p1',
          createdAt: now,
          isUrgent: true,
          status: TaskStatus.todo,
          sortOrder: '0',
        );
        final normalRoot = Task(
          id: 'r2',
          title: 'Normal Root',
          createdAt: now,
          isUrgent: false,
          sortOrder: 'a0',
        );

        // Input list: normalRoot was earlier in sortOrder ('a0' vs 'b0')
        final result = TaskHierarchyUtils.buildHierarchy([
          normalRoot,
          parent,
          urgentSub,
        ]);

        expect(result.length, 3);
        // Parent elevated to urgent section above normalRoot
        expect((result[0] as TaskNode).task.id, 'p1');
        expect(result[0].depth, 0);

        expect((result[1] as TaskNode).task.id, 's1');
        expect(result[1].depth, 1);

        expect((result[2] as TaskNode).task.id, 'r2');
        expect(result[2].depth, 0);
      },
    );

    test(
      'buildHierarchy does not elevate parent if urgent subtask is completed',
      () {
        final parent = Task(
          id: 'p1',
          title: 'Parent',
          createdAt: now,
          isUrgent: false,
          sortOrder: 'b0',
        );
        final completedUrgentSub = Task(
          id: 's1',
          title: 'Completed Urgent Sub',
          parentId: 'p1',
          createdAt: now,
          isUrgent: true,
          status: TaskStatus.done,
          sortOrder: '0',
        );
        final normalRoot = Task(
          id: 'r2',
          title: 'Normal Root',
          createdAt: now,
          isUrgent: false,
          sortOrder: 'a0',
        );

        final result = TaskHierarchyUtils.buildHierarchy([
          normalRoot,
          parent,
          completedUrgentSub,
        ]);

        expect(result.length, 3);
        // Normal root stays first because parent has no active urgent subtask
        expect((result[0] as TaskNode).task.id, 'r2');
        expect(result[0].depth, 0);

        expect((result[1] as TaskNode).task.id, 'p1');
        expect(result[1].depth, 0);

        expect((result[2] as TaskNode).task.id, 's1');
        expect(result[2].depth, 1);
      },
    );

    test(
      'buildHierarchy preserves relative root sortOrder among effectively urgent parents',
      () {
        final parentA = Task(
          id: 'pa',
          title: 'Parent A',
          createdAt: now,
          isUrgent: false,
          sortOrder: 'a0',
        );
        final subA = Task(
          id: 'sa',
          title: 'Sub A',
          parentId: 'pa',
          createdAt: now,
          isUrgent: true,
          status: TaskStatus.todo,
          sortOrder: '0',
        );
        final parentB = Task(
          id: 'pb',
          title: 'Parent B',
          createdAt: now,
          isUrgent: false,
          sortOrder: 'b0',
        );
        final subB = Task(
          id: 'sb',
          title: 'Sub B',
          parentId: 'pb',
          createdAt: now,
          isUrgent: true,
          status: TaskStatus.todo,
          sortOrder: '0',
        );

        final result = TaskHierarchyUtils.buildHierarchy([
          parentA,
          subA,
          parentB,
          subB,
        ]);

        expect(result.length, 4);
        expect((result[0] as TaskNode).task.id, 'pa');
        expect((result[1] as TaskNode).task.id, 'sa');
        expect((result[2] as TaskNode).task.id, 'pb');
        expect((result[3] as TaskNode).task.id, 'sb');
      },
    );
  });
}
