import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderEngine bottom placement and sole-task tests', () {
    final now = DateTime(2026);
    const settings = SettingsState({});

    Task makeTask(
      String id,
      String sort, {
      String? parentId,
      DateTime? deadline,
    }) => Task(
      id: id,
      title: id,
      createdAt: now,
      sortOrder: sort,
      parentId: parentId,
      deadline: deadline,
    );

    test(
      'dragging task to bottom after unranked tasks places after last ranked task',
      () {
        final t1 = makeTask('t1', 'a0');
        final t2 = makeTask('t2', 'a2');
        final unranked = makeTask('unranked', '');

        final nodes = <TaskHierarchyNode>[
          TaskNode(t1, 0),
          TaskNode(t2, 0),
          TaskNode(unranked, 0),
        ];

        // Drag t1 to slot 3 (bottom)
        final slot = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: t1,
          rawIndex: 3,
          settings: settings,
        );

        expect(slot.isValid, isTrue);

        final ranks = TaskReorderEngine.computeRanks(
          nodes: nodes,
          draggedTask: t1,
          slot: slot,
          settings: settings,
        );

        expect(ranks, isNotNull);
        final newRank = ranks![t1.id]!;
        expect(newRank.compareTo('a2'), greaterThan(0));
        expect(newRank.compareTo('a0'), greaterThan(0));
      },
    );

    test('sole task in group returns null when position cannot change', () {
      final sole = makeTask('sole', 'a5');
      final nodes = <TaskHierarchyNode>[TaskNode(sole, 0)];

      final slot = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: sole,
        rawIndex: 1,
        settings: settings,
      );

      expect(slot.isValid, isTrue);

      final ranks = TaskReorderEngine.computeRanks(
        nodes: nodes,
        draggedTask: sole,
        slot: slot,
        settings: settings,
      );

      expect(ranks, isNull);
    });

    test('sole parent dropped below its own subtasks returns null', () {
      final parent = makeTask('parent', 'a2');
      final sub1 = makeTask('sub1', 's0', parentId: 'parent');
      final sub2 = makeTask('sub2', 's1', parentId: 'parent');

      final nodes = <TaskHierarchyNode>[
        TaskNode(parent, 0),
        TaskNode(sub1, 1, isBundledUnderParent: true),
        TaskNode(sub2, 1, isBundledUnderParent: true),
      ];

      final slot = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: parent,
        rawIndex: 3,
        settings: settings,
      );

      expect(slot.isValid, isTrue);

      final ranks = TaskReorderEngine.computeRanks(
        nodes: nodes,
        draggedTask: parent,
        slot: slot,
        settings: settings,
      );

      expect(ranks, isNull);
    });

    test(
      'TaskReorderService.computeSortOrder with bottom placement scans past unranked tasks',
      () {
        final t1 = makeTask('t1', 'a2');
        final t2 = makeTask('t2', '');

        final sortOrder = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.bottom,
          activeList: [t1, t2],
        );

        expect(sortOrder.compareTo('a2'), greaterThan(0));
      },
    );

    test('sole task in deadline group does not jump to top', () {
      const deadlineSettings = SettingsState({
        SettingsConstants.keyPrioritizeDeadlines: 'true',
      });

      final d1 = DateTime(2026, 5, 1);
      final d2 = DateTime(2026, 5, 2);

      final t1 = makeTask('t1', 'a0', deadline: d1);
      final t2 = makeTask('t2', 'a1', deadline: d1);
      final t3 = makeTask('t3', 'b0', deadline: d2);

      final nodes = <TaskHierarchyNode>[
        TaskNode(t1, 0),
        TaskNode(t2, 0),
        TaskNode(t3, 0),
      ];

      final newRank = TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: t3,
        newIndex: 3,
        settings: deadlineSettings,
      );

      expect(newRank, isNull);
    });
  });
}
