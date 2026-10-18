import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_hierarchy_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task reordering child task into lone parent without siblings', () {
    final now = DateTime(2026);
    const settings = SettingsState({});

    Task makeTask(String id, String sort, {String? parentId}) => Task(
      id: id,
      title: id,
      createdAt: now,
      sortOrder: sort,
      parentId: parentId,
    );

    test('resolveSlot targets parentIdx + 1 and is valid', () {
      final parent = makeTask('p1', 'a0');
      final other = makeTask('r1', 'a1');
      final child = makeTask('c1', 'a0', parentId: 'p1');

      final nodes = <TaskHierarchyNode>[
        TaskNode(parent, 0),
        TaskNode(other, 0),
      ];

      // rawIndex anywhere in list should resolve to slot 1 (parentIdx + 1)
      final slotAt0 = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: child,
        rawIndex: 0,
        settings: settings,
      );
      expect(slotAt0.isValid, isTrue);
      expect(slotAt0.index, 1);
      expect(slotAt0.isUnchanged, isFalse);

      final slotAt2 = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: child,
        rawIndex: 2,
        settings: settings,
      );
      expect(slotAt2.isValid, isTrue);
      expect(slotAt2.index, 1);
      expect(slotAt2.isUnchanged, isFalse);
    });

    test('isPositionValidInNodes validates parentIdx + 1 only', () {
      final parent = makeTask('p1', 'a0');
      final other = makeTask('r1', 'a1');
      final child = makeTask('c1', 'a0', parentId: 'p1');

      final nodes = <TaskHierarchyNode>[
        TaskNode(parent, 0),
        TaskNode(other, 0),
      ];

      expect(
        TaskHierarchyReorderUtils.isPositionValidInNodes(
          draggedTask: child,
          targetIndex: 0,
          nodes: nodes,
          settings: settings,
        ),
        isFalse,
      );

      expect(
        TaskHierarchyReorderUtils.isPositionValidInNodes(
          draggedTask: child,
          targetIndex: 1,
          nodes: nodes,
          settings: settings,
        ),
        isTrue,
      );

      expect(
        TaskHierarchyReorderUtils.isPositionValidInNodes(
          draggedTask: child,
          targetIndex: 2,
          nodes: nodes,
          settings: settings,
        ),
        isFalse,
      );
    });

    test('computeRanks generates defaultRank for lone subtask in group', () {
      final parent = makeTask('p1', 'a0');
      final other = makeTask('r1', 'a1');
      final child = makeTask('c1', 'a0', parentId: 'p1');

      final nodes = <TaskHierarchyNode>[
        TaskNode(parent, 0),
        TaskNode(other, 0),
      ];

      final slot = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: child,
        rawIndex: 1,
        settings: settings,
      );

      final ranks = TaskReorderEngine.computeRanks(
        nodes: nodes,
        draggedTask: child,
        slot: slot,
        settings: settings,
      );

      expect(ranks, isNotNull);
      expect(ranks![child.id], LexoRank.defaultRank);
    });

    test('handleReorder returns sortOrder when dropping under lone parent', () {
      final parent = makeTask('p1', 'a0');
      final other = makeTask('r1', 'a1');
      final child = makeTask('c1', 'a0', parentId: 'p1');

      final nodes = <TaskHierarchyNode>[
        TaskNode(parent, 0),
        TaskNode(other, 0),
      ];

      final newOrder = TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: child,
        newIndex: 1,
        settings: settings,
      );

      expect(newOrder, equals(LexoRank.defaultRank));
    });
  });
}
