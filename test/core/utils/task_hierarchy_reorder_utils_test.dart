import 'package:carpe_diem/core/utils/task_hierarchy_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskHierarchyReorderUtils', () {
    final now = DateTime.now();

    final rootA = Task(id: 'a', title: 'Root A', createdAt: now);
    final parentB = Task(id: 'b', title: 'Parent B', createdAt: now);
    final subB1 = Task(
      id: 'b1',
      title: 'Subtask B1',
      parentId: 'b',
      createdAt: now,
    );
    final subB2 = Task(
      id: 'b2',
      title: 'Subtask B2',
      parentId: 'b',
      createdAt: now,
    );
    final rootC = Task(id: 'c', title: 'Root C', createdAt: now);

    final nodes = <TaskHierarchyNode>[
      TaskNode(rootA, 0),
      ParentContainerNode(task: parentB, depth: 0),
      TaskNode(subB1, 1, isBundledUnderParent: true),
      TaskNode(subB2, 1, isBundledUnderParent: true),
      TaskNode(rootC, 0),
    ];

    group('Normal task (parentId == null)', () {
      test('valid at root slots (0, 1, 4, 5)', () {
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: rootA,
            targetIndex: 0,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: rootA,
            targetIndex: 1,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: rootA,
            targetIndex: 4,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: rootA,
            targetIndex: 5,
            nodes: nodes,
          ),
          isTrue,
        );
      });

      test('invalid at subtask slots (2, 3)', () {
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: rootA,
            targetIndex: 2,
            nodes: nodes,
          ),
          isFalse,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: rootA,
            targetIndex: 3,
            nodes: nodes,
          ),
          isFalse,
        );
      });
    });

    group('Child task (parentId != null)', () {
      test('valid within its parent slots (2, 3, 4)', () {
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: subB1,
            targetIndex: 2,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: subB1,
            targetIndex: 3,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: subB1,
            targetIndex: 4,
            nodes: nodes,
          ),
          isTrue,
        );
      });

      test('invalid outside its parent slots (0, 1, 5)', () {
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: subB1,
            targetIndex: 0,
            nodes: nodes,
          ),
          isFalse,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: subB1,
            targetIndex: 1,
            nodes: nodes,
          ),
          isFalse,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: subB1,
            targetIndex: 5,
            nodes: nodes,
          ),
          isFalse,
        );
      });
    });

    group('isLastChildInGroup', () {
      test('identifies last child in group correctly', () {
        expect(
          TaskHierarchyReorderUtils.isLastChildInGroup(
            task: subB1,
            index: 2,
            nodes: nodes,
          ),
          isFalse,
        );
        expect(
          TaskHierarchyReorderUtils.isLastChildInGroup(
            task: subB1,
            index: 3,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isLastChildInGroup(
            task: rootA,
            index: 0,
            nodes: nodes,
          ),
          isFalse,
        );
      });
    });
  });
}
