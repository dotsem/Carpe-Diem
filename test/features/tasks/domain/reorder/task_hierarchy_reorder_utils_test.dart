import 'package:carpe_diem/features/tasks/domain/reorder/task_hierarchy_reorder_utils.dart';
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

    bool isValid(Task task, int idx) =>
        TaskHierarchyReorderUtils.isPositionValidInNodes(
          draggedTask: task,
          targetIndex: idx,
          nodes: nodes,
        );

    group('Normal task (parentId == null)', () {
      test('valid at root slots (0, 1, 4, 5)', () {
        expect(isValid(rootA, 0), isTrue);
        expect(isValid(rootA, 1), isTrue);
        expect(isValid(rootA, 4), isTrue);
        expect(isValid(rootA, 5), isTrue);
      });

      test('invalid at subtask slots (2, 3)', () {
        expect(isValid(rootA, 2), isFalse);
        expect(isValid(rootA, 3), isFalse);
      });
    });

    group('Child task (parentId != null)', () {
      test('valid within its parent slots (2, 3, 4)', () {
        expect(isValid(subB1, 2), isTrue);
        expect(isValid(subB1, 3), isTrue);
        expect(isValid(subB1, 4), isTrue);
      });

      test('invalid outside its parent slots (0, 1, 5)', () {
        expect(isValid(subB1, 0), isFalse);
        expect(isValid(subB1, 1), isFalse);
        expect(isValid(subB1, 5), isFalse);
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

    group('Orphan subtask (parentId != null, parent not in nodes)', () {
      final orphanSub = Task(
        id: 'orphan1',
        parentId: 'missing_parent',
        title: 'Orphan Subtask',
        createdAt: now,
      );

      test('valid at root slots (0, 1, 4, 5)', () {
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: orphanSub,
            targetIndex: 0,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: orphanSub,
            targetIndex: 1,
            nodes: nodes,
          ),
          isTrue,
        );
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: orphanSub,
            targetIndex: 4,
            nodes: nodes,
          ),
          isTrue,
        );
      });

      test('invalid inside other parent subtask slots', () {
        expect(
          TaskHierarchyReorderUtils.isPositionValidInNodes(
            draggedTask: orphanSub,
            targetIndex: 2,
            nodes: nodes,
          ),
          isFalse,
        );
      });
    });

    group('getClampedTopIndex and getClampedBottomIndex', () {
      test(
        'root task clamps to 0 and nodes.length when no urgency section',
        () {
          expect(
            TaskHierarchyReorderUtils.getClampedTopIndex(
              task: rootA,
              nodes: nodes,
              urgentSectionEndIndex: 0,
            ),
            equals(0),
          );
          expect(
            TaskHierarchyReorderUtils.getClampedBottomIndex(
              task: rootA,
              nodes: nodes,
              urgentSectionEndIndex: 0,
            ),
            equals(nodes.length),
          );
        },
      );

      test('subtask clamps strictly to parent children range', () {
        expect(
          TaskHierarchyReorderUtils.getClampedTopIndex(
            task: subB1,
            nodes: nodes,
            urgentSectionEndIndex: 0,
          ),
          equals(2),
        );
        expect(
          TaskHierarchyReorderUtils.getClampedBottomIndex(
            task: subB1,
            nodes: nodes,
            urgentSectionEndIndex: 0,
          ),
          equals(4),
        );
      });

      test(
        'respects urgent section boundaries for urgent and normal tasks',
        () {
          final urgentTask = Task(
            id: 'u',
            title: 'Urgent',
            isUrgent: true,
            createdAt: now,
          );
          final normalTask = Task(
            id: 'n',
            title: 'Normal',
            isUrgent: false,
            createdAt: now,
          );

          expect(
            TaskHierarchyReorderUtils.getClampedBottomIndex(
              task: urgentTask,
              nodes: nodes,
              urgentSectionEndIndex: 2,
            ),
            equals(2),
          );
          expect(
            TaskHierarchyReorderUtils.getClampedTopIndex(
              task: normalTask,
              nodes: nodes,
              urgentSectionEndIndex: 2,
            ),
            equals(2),
          );
        },
      );

      test(
        'normal task clamps to index 0 when top node is non-urgent parent',
        () {
          final normalTask = Task(
            id: 'n',
            title: 'Normal',
            isUrgent: false,
            createdAt: now,
          );
          final nodesWithParentTop = <TaskHierarchyNode>[
            ParentContainerNode(task: parentB, depth: 0),
            TaskNode(subB1, 1, isBundledUnderParent: true),
            TaskNode(rootC, 0),
          ];
          expect(
            TaskHierarchyReorderUtils.getClampedTopIndex(
              task: normalTask,
              nodes: nodesWithParentTop,
              urgentSectionEndIndex: 0,
            ),
            equals(0),
          );
        },
      );
    });
  });
}
