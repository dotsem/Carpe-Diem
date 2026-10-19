import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderEngine bottom-most parent with subtasks', () {
    final now = DateTime(2026);
    const settings = SettingsState({});

    Task makeTask(
      String id,
      String sort, {
      String? parentId,
      String? planSort,
    }) => Task(
      id: id,
      title: id,
      createdAt: now,
      sortOrder: sort,
      parentId: parentId,
      planSortOrder: planSort,
    );

    test(
      'isPositionInGroup allows root task to drop below bottom-most parent subtasks',
      () {
        final dragged = makeTask('r1', 'a0');
        final parent = makeTask('p1', 'a2');
        final sub1 = makeTask('s1', 's0', parentId: 'p1');
        final sub2 = makeTask('s2', 's1', parentId: 'p1');

        final nodes = <TaskHierarchyNode>[
          TaskNode(dragged, 0),
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
          TaskNode(sub2, 1, isBundledUnderParent: true),
        ];

        final inGroup = TaskReorderEngine.isPositionInGroup(
          nodes: nodes,
          draggedTask: dragged,
          targetIndex: 4,
          settings: settings,
          isPlanView: false,
        );

        expect(inGroup, isTrue);
      },
    );

    test(
      'isPositionInGroup allows root task to drop below bottom-most parent in plan view',
      () {
        final dragged = makeTask('r1', 'a0', planSort: 'a0');
        final parent = makeTask('p1', 'a2', planSort: 'a2');
        final sub1 = makeTask('s1', 's0', parentId: 'p1', planSort: 'a0');
        final sub2 = makeTask('s2', 's1', parentId: 'p1', planSort: 'a1');

        final nodes = <TaskHierarchyNode>[
          TaskNode(dragged, 0),
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
          TaskNode(sub2, 1, isBundledUnderParent: true),
        ];

        final inGroup = TaskReorderEngine.isPositionInGroup(
          nodes: nodes,
          draggedTask: dragged,
          targetIndex: 4,
          settings: settings,
          isPlanView: true,
        );

        expect(inGroup, isTrue);
      },
    );

    test(
      'handleReorder reorders root task below bottom-most parent with subtasks',
      () {
        final dragged = makeTask('r1', 'a0');
        final parent = makeTask('p1', 'a2');
        final sub1 = makeTask('s1', 's0', parentId: 'p1');
        final sub2 = makeTask('s2', 's1', parentId: 'p1');

        final nodes = <TaskHierarchyNode>[
          TaskNode(dragged, 0),
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
          TaskNode(sub2, 1, isBundledUnderParent: true),
        ];

        final newSortOrder = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: dragged,
          newIndex: 4,
          settings: settings,
        );

        expect(newSortOrder, isNotNull);
        expect(newSortOrder!.compareTo('a2'), greaterThan(0));
      },
    );

    test(
      'handleReorder in plan view reorders root task below bottom-most parent with subtasks',
      () {
        final dragged = makeTask('r1', 'a0', planSort: 'a0');
        final parent = makeTask('p1', 'a2', planSort: 'a2');
        final sub1 = makeTask('s1', 's0', parentId: 'p1', planSort: 'a0');
        final sub2 = makeTask('s2', 's1', parentId: 'p1', planSort: 'a1');

        final nodes = <TaskHierarchyNode>[
          TaskNode(dragged, 0),
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
          TaskNode(sub2, 1, isBundledUnderParent: true),
        ];

        final newSortOrder = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: dragged,
          newIndex: 4,
          settings: settings,
          isPlanView: true,
        );

        expect(newSortOrder, isNotNull);
        expect(newSortOrder!.compareTo('a2'), greaterThan(0));
      },
    );

    test(
      'resolveSlot produces valid slot when hovering below bottom subtask',
      () {
        final dragged = makeTask('r1', 'a0', planSort: 'a0');
        final parent = makeTask('p1', 'a2', planSort: 'a2');
        final sub1 = makeTask('s1', 's0', parentId: 'p1', planSort: 'a0');

        final nodes = <TaskHierarchyNode>[
          TaskNode(dragged, 0),
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
        ];

        final slot = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: dragged,
          rawIndex: 3,
          settings: settings,
          isPlanView: true,
        );

        expect(slot.isValid, isTrue);
        expect(slot.index, 3);
      },
    );

    test(
      'resolveSlot snaps outside when root task hovers over bottom parent subtasks',
      () {
        final dragged = makeTask('r1', 'a0');
        final parent = makeTask('p1', 'a2');
        final sub1 = makeTask('s1', 's0', parentId: 'p1');
        final sub2 = makeTask('s2', 's1', parentId: 'p1');

        final nodes = <TaskHierarchyNode>[
          TaskNode(dragged, 0),
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
          TaskNode(sub2, 1, isBundledUnderParent: true),
        ];

        final slot = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: dragged,
          rawIndex: 3,
          settings: settings,
        );

        expect(slot.isValid, isTrue);
        expect(slot.index, 4);
      },
    );
  });
}
