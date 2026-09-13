import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderUtils hierarchy reordering', () {
    final now = DateTime.now();
    const settings = SettingsState({});

    test(
      'handleReorder dropping root task below a subtask places it after parent',
      () {
        final parent = Task(
          id: 'p1',
          title: 'Parent',
          createdAt: now,
          sortOrder: 'a0',
        );
        final sub1 = Task(
          id: 's1',
          title: 'Subtask 1',
          parentId: 'p1',
          createdAt: now,
          sortOrder: '0',
        );
        final otherRoot = Task(
          id: 'r2',
          title: 'Root 2',
          createdAt: now,
          sortOrder: 'a2',
        );
        final dragged = Task(
          id: 'r3',
          title: 'Root 3',
          createdAt: now,
          sortOrder: 'a4',
        );

        final nodes = TaskHierarchyUtils.buildHierarchy([
          parent,
          sub1,
          otherRoot,
          dragged,
        ]);

        // nodes: [0: Parent (a0), 1: Subtask 1, 2: Root 2 (a2), 3: Root 3 (a4)]
        // Dropping dragged below Subtask 1 (index 1 -> drop at newIndex 2)
        final newSortOrder = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: dragged,
          newIndex: 2,
          settings: settings,
        );

        expect(newSortOrder, isNotNull);
        expect(newSortOrder!.compareTo('a0'), greaterThan(0));
        expect(newSortOrder.compareTo('a2'), lessThan(0));
      },
    );

    test(
      'handleReorder dropping root task below last subtask places it inline after parent',
      () {
        final parent = Task(
          id: 'p1',
          title: 'Parent',
          createdAt: now,
          sortOrder: 'a0',
        );
        final sub1 = Task(
          id: 's1',
          title: 'Subtask 1',
          parentId: 'p1',
          createdAt: now,
          sortOrder: '0',
        );
        final sub2 = Task(
          id: 's2',
          title: 'Subtask 2',
          parentId: 'p1',
          createdAt: now,
          sortOrder: '1',
        );
        final nextRoot = Task(
          id: 'r2',
          title: 'Next Root',
          createdAt: now,
          sortOrder: 'a2',
        );
        final dragged = Task(
          id: 'r3',
          title: 'Dragged Root',
          createdAt: now,
          sortOrder: 'a4',
        );

        final nodes = <TaskHierarchyNode>[
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
          TaskNode(sub2, 1, isBundledUnderParent: true),
          TaskNode(nextRoot, 0),
          TaskNode(dragged, 0),
        ];

        final newSortOrder = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: dragged,
          newIndex: 3,
          settings: settings,
        );

        expect(newSortOrder, isNotNull);
        expect(newSortOrder!.compareTo('a0'), greaterThan(0));
        expect(newSortOrder.compareTo('a2'), lessThan(0));
      },
    );

    test(
      'handleReorder moving subtask within siblings calculates valid sibling rank',
      () {
        final parent = Task(
          id: 'p1',
          title: 'Parent',
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
          sortOrder: 'a3',
        );

        final nodes = <TaskHierarchyNode>[
          TaskNode(parent, 0),
          TaskNode(sub1, 1, isBundledUnderParent: true),
          TaskNode(sub2, 1, isBundledUnderParent: true),
        ];

        final newSortOrder = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: sub2,
          newIndex: 1,
          settings: settings,
        );

        expect(newSortOrder, isNotNull);
        expect(newSortOrder!.compareTo('a1'), lessThan(0));
      },
    );
  });
}
