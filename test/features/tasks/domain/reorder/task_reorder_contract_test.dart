import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/task_sort_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderEngine Contract Tests', () {
    final now = DateTime.now();
    const defaultSettings = SettingsState({});

    test('1. Root Task standard movement to top, middle, and bottom', () {
      final a = Task(id: 'a', title: 'A', sortOrder: 'a0', createdAt: now);
      final b = Task(id: 'b', title: 'B', sortOrder: 'a2', createdAt: now);
      final c = Task(id: 'c', title: 'C', sortOrder: 'a4', createdAt: now);
      final nodes = TaskHierarchyUtils.buildHierarchy([a, b, c]);

      // Move C to top (0)
      final slotTop = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: c,
        rawIndex: 0,
      );
      expect(slotTop.index, equals(0));
      expect(slotTop.isValid, isTrue);
      expect(slotTop.isUnchanged, isFalse);

      final ranksTop = TaskReorderEngine.computeRanks(
        nodes: nodes,
        draggedTask: c,
        slot: slotTop,
      );
      expect(ranksTop, isNotNull);
      expect(ranksTop!['c']!.compareTo('a0'), lessThan(0));

      // Move A to bottom (3)
      final slotBottom = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: a,
        rawIndex: 3,
      );
      expect(slotBottom.index, equals(3));
      final ranksBottom = TaskReorderEngine.computeRanks(
        nodes: nodes,
        draggedTask: a,
        slot: slotBottom,
      );
      expect(ranksBottom!['a']!.compareTo('a4'), greaterThan(0));
    });

    test('2. Root Task out-of-bounds clamping (< 0 and > length)', () {
      final a = Task(id: 'a', title: 'A', sortOrder: 'a0', createdAt: now);
      final b = Task(id: 'b', title: 'B', sortOrder: 'a2', createdAt: now);
      final nodes = TaskHierarchyUtils.buildHierarchy([a, b]);

      final farAbove = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: b,
        rawIndex: -50,
      );
      expect(farAbove.index, equals(0));

      final farBelow = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: a,
        rawIndex: 500,
      );
      expect(farBelow.index, equals(2));
    });

    test(
      '3. Rule B: Root task auto-snaps outside parent when dropped into subtasks',
      () {
        final parent = Task(
          id: 'p',
          title: 'Parent',
          sortOrder: 'a0',
          createdAt: now,
        );
        final sub1 = Task(
          id: 's1',
          title: 'Sub 1',
          parentId: 'p',
          sortOrder: '0',
          createdAt: now,
        );
        final sub2 = Task(
          id: 's2',
          title: 'Sub 2',
          parentId: 'p',
          sortOrder: '1',
          createdAt: now,
        );
        final dragged = Task(
          id: 'd',
          title: 'Dragged',
          sortOrder: 'a9',
          createdAt: now,
        );

        final nodes = TaskHierarchyUtils.buildHierarchy([
          parent,
          sub1,
          sub2,
          dragged,
        ], asParentContainers: true);
        // nodes: [0: ParentContainer(p), 1: Subtask(s1), 2: Subtask(s2), 3: TaskNode(d)]

        // Dropping into index 1 (upper half of subtasks) snaps before parent (index 0)
        final snapBefore = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: dragged,
          rawIndex: 1,
        );
        expect(snapBefore.index, equals(0));
        expect(snapBefore.isValid, isTrue);

        // Dropping into index 2 (lower half of subtasks) snaps after parent container (index 3)
        final snapAfter = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: dragged,
          rawIndex: 2,
        );
        expect(snapAfter.index, equals(3));
        expect(snapAfter.isValid, isTrue);
      },
    );

    test(
      '4. Subtask isolation: clamps strictly to parent range and never reparents',
      () {
        final rootBefore = Task(
          id: 'r0',
          title: 'Root 0',
          sortOrder: 'a0',
          createdAt: now,
        );
        final parent = Task(
          id: 'p',
          title: 'Parent',
          sortOrder: 'a2',
          createdAt: now,
        );
        final sub1 = Task(
          id: 's1',
          title: 'Sub 1',
          parentId: 'p',
          sortOrder: '0',
          createdAt: now,
        );
        final sub2 = Task(
          id: 's2',
          title: 'Sub 2',
          parentId: 'p',
          sortOrder: '1',
          createdAt: now,
        );
        final rootAfter = Task(
          id: 'r1',
          title: 'Root 1',
          sortOrder: 'a4',
          createdAt: now,
        );

        final nodes = TaskHierarchyUtils.buildHierarchy([
          rootBefore,
          parent,
          sub1,
          sub2,
          rootAfter,
        ], asParentContainers: true);
        // nodes: [0: r0, 1: Parent(p), 2: s1, 3: s2, 4: r1]

        // Drag sub2 far above (e.g. index 0 or -10) -> clamps to index 2 (first child under p)
        final clampTop = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: sub2,
          rawIndex: -10,
        );
        expect(clampTop.index, equals(2));

        // Drag sub1 far below (e.g. index 4 or 100) -> clamps to index 4 (end of children under p)
        final clampBottom = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: sub1,
          rawIndex: 100,
        );
        expect(clampBottom.index, equals(4));
      },
    );

    test('5. Urgency boundaries enforce pinning and trapping', () {
      final urgent1 = Task(
        id: 'u1',
        title: 'Urgent',
        isUrgent: true,
        sortOrder: 'a0',
        createdAt: now,
      );
      final normal1 = Task(
        id: 'n1',
        title: 'Normal 1',
        isUrgent: false,
        sortOrder: 'a2',
        createdAt: now,
      );
      final normal2 = Task(
        id: 'n2',
        title: 'Normal 2',
        isUrgent: false,
        sortOrder: 'a4',
        createdAt: now,
      );

      final nodes = TaskHierarchyUtils.buildHierarchy([
        urgent1,
        normal1,
        normal2,
      ]);
      // urgentEnd is 1

      // Normal task dragged to top (-5) snaps to urgent boundary (index 1)
      final normalToTop = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: normal2,
        rawIndex: -5,
      );
      expect(normalToTop.index, equals(1));

      // Urgent task dragged to bottom (99) snaps to urgent boundary (index 1)
      final urgentToBottom = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: urgent1,
        rawIndex: 99,
      );
      expect(urgentToBottom.index, equals(1));
    });

    test('6. Deadlines partitioning in daily view vs plan view', () {
      final today = DateTime(2026, 10, 15);
      final tomorrow = DateTime(2026, 10, 16);
      final t1 = Task(
        id: 't1',
        title: 'T1',
        deadline: today,
        sortOrder: 'a0',
        createdAt: now,
      );
      final t2 = Task(
        id: 't2',
        title: 'T2',
        deadline: tomorrow,
        sortOrder: 'a2',
        createdAt: now,
      );

      final nodes = TaskHierarchyUtils.buildHierarchy([t1, t2]);
      const deadlineSettings = SettingsState({'prioritizeDeadlines': 'true'});

      // Daily view: dragging across deadline boundary is invalid
      final dailySlot = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: t2,
        rawIndex: 0,
        settings: deadlineSettings,
        isPlanView: false,
      );
      expect(dailySlot.isValid, isFalse);

      // Plan view: dragging across deadline boundary is permitted
      final planSlot = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: t2,
        rawIndex: 0,
        settings: deadlineSettings,
        isPlanView: true,
      );
      expect(planSlot.isValid, isTrue);
      expect(planSlot.index, equals(0));
    });

    test('7. Multi-selection reorder assigns contiguous relative ranks', () {
      final a = Task(id: 'a', title: 'A', sortOrder: 'a0', createdAt: now);
      final b = Task(id: 'b', title: 'B', sortOrder: 'a2', createdAt: now);
      final c = Task(id: 'c', title: 'C', sortOrder: 'a4', createdAt: now);
      final d = Task(id: 'd', title: 'D', sortOrder: 'a6', createdAt: now);

      final nodes = TaskHierarchyUtils.buildHierarchy([a, b, c, d]);
      final slot = TaskReorderEngine.resolveSlot(
        nodes: nodes,
        draggedTask: b,
        rawIndex: 4,
      );

      final ranks = TaskReorderEngine.computeRanks(
        nodes: nodes,
        draggedTask: b,
        slot: slot,
        selectedTaskIds: {'b', 'c'},
      );

      expect(ranks, isNotNull);
      expect(ranks!.containsKey('b'), isTrue);
      expect(ranks.containsKey('c'), isTrue);
      expect(ranks['b']!.compareTo(ranks['c']!), lessThan(0));
      expect(ranks['b']!.compareTo('a6'), greaterThan(0));
    });

    test(
      '8. Unchanged position / no-op returns isUnchanged true and null ranks',
      () {
        final a = Task(id: 'a', title: 'A', sortOrder: 'a0', createdAt: now);
        final b = Task(id: 'b', title: 'B', sortOrder: 'a2', createdAt: now);
        final nodes = TaskHierarchyUtils.buildHierarchy([a, b]);

        // Dropping at current index (1) or right after (2) is no-op
        final slotSame = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: b,
          rawIndex: 1,
        );
        expect(slotSame.isUnchanged, isTrue);

        final ranksSame = TaskReorderEngine.computeRanks(
          nodes: nodes,
          draggedTask: b,
          slot: slotSame,
        );
        expect(ranksSame, isNull);

        final slotAfter = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: b,
          rawIndex: 2,
        );
        expect(slotAfter.isUnchanged, isTrue);
      },
    );

    test(
      '9. Observable behavioral outcome: sorted list matches expected order',
      () {
        final a = Task(id: 'a', title: 'A', sortOrder: 'a0', createdAt: now);
        final b = Task(id: 'b', title: 'B', sortOrder: 'a2', createdAt: now);
        final c = Task(id: 'c', title: 'C', sortOrder: 'a4', createdAt: now);

        final nodes = TaskHierarchyUtils.buildHierarchy([a, b, c]);
        final slot = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: c,
          rawIndex: 0,
        );
        final ranks = TaskReorderEngine.computeRanks(
          nodes: nodes,
          draggedTask: c,
          slot: slot,
        )!;

        final updated = [a, b, c.copyWith(sortOrder: ranks['c'])];
        TaskSortUtils.sortTasks(updated, defaultSettings);

        expect(updated.map((t) => t.id).toList(), equals(['c', 'a', 'b']));
      },
    );
  });
}
