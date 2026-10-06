import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskHierarchyUtils collapsed parents', () {
    final now = DateTime.now();

    test(
      'buildHierarchy hides subtasks when parent is collapsed without leaking to root',
      () {
        final parent = Task(
          id: 'parent_1',
          title: 'Parent 1',
          createdAt: now,
          sortOrder: 'a0',
        );
        final subtask = Task(
          id: 'sub_1',
          title: 'Subtask 1',
          parentId: 'parent_1',
          createdAt: now,
          sortOrder: '0',
        );
        final otherRoot = Task(
          id: 'root_2',
          title: 'Root 2',
          createdAt: now,
          sortOrder: 'b0',
        );

        final result = TaskHierarchyUtils.buildHierarchy(
          [parent, subtask, otherRoot],
          collapsedParentIds: {'parent_1'},
        );

        expect(result.length, 2);
        expect((result[0] as TaskNode).task.id, 'parent_1');
        expect(result[0].depth, 0);

        expect((result[1] as TaskNode).task.id, 'root_2');
        expect(result[1].depth, 0);
      },
    );

    test(
      'buildHierarchy with asParentContainers hides subtasks and sets isCollapsed',
      () {
        final parent = Task(id: 'parent_1', title: 'Parent 1', createdAt: now);
        final subtask1 = Task(
          id: 'sub_1',
          title: 'Sub 1',
          parentId: 'parent_1',
          createdAt: now,
        );
        final subtask2 = Task(
          id: 'sub_2',
          title: 'Sub 2',
          parentId: 'parent_1',
          createdAt: now,
        );

        final result = TaskHierarchyUtils.buildHierarchy(
          [parent, subtask1, subtask2],
          collapsedParentIds: {'parent_1'},
          asParentContainers: true,
        );

        expect(result.length, 1);
        expect(result[0], isA<ParentContainerNode>());
        final node = result[0] as ParentContainerNode;
        expect(node.task.id, 'parent_1');
        expect(node.isCollapsed, isTrue);
        expect(node.totalSubtasks, 2);
      },
    );

    test(
      'buildHierarchy hides nested descendants when ancestor is collapsed',
      () {
        final grandparent = Task(
          id: 'gp_1',
          title: 'Grandparent',
          createdAt: now,
        );
        final parent = Task(
          id: 'p_1',
          title: 'Parent',
          parentId: 'gp_1',
          createdAt: now,
        );
        final child = Task(
          id: 'c_1',
          title: 'Child',
          parentId: 'p_1',
          createdAt: now,
        );

        final result = TaskHierarchyUtils.buildHierarchy(
          [grandparent, parent, child],
          collapsedParentIds: {'gp_1'},
        );

        expect(result.length, 1);
        expect((result[0] as TaskNode).task.id, 'gp_1');
      },
    );
  });
}
