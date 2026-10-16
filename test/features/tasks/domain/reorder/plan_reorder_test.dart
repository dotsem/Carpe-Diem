import 'package:carpe_diem/features/tasks/domain/reorder/task_hierarchy_reorder_utils.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/core/utils/task_sort_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('plan reorder scenarios', () {
    final now = DateTime.now();
    const settings = SettingsState({});

    test('reorder sibling subtasks at indent 0 in plan view', () {
      final child1 = Task(
        id: 'c1',
        title: 'Child 1',
        parentId: 'p1',
        sortOrder: 'a0',
        createdAt: now,
      );
      final child2 = Task(
        id: 'c2',
        title: 'Child 2',
        parentId: 'p1',
        sortOrder: 'a1',
        createdAt: now,
      );

      final nodes = TaskHierarchyUtils.buildHierarchy([child1, child2]);
      expect(nodes[0].depth, equals(0));
      expect(nodes[1].depth, equals(0));

      final newRank = TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: child2,
        newIndex: 0,
        settings: settings,
        isPlanView: true,
      );
      expect(newRank, isNotNull);

      final list = [child1, child2.copyWith(planSortOrder: newRank!)];
      TaskSortUtils.sortTasks(list, settings, isPlanView: true);
      expect(list.first.id, equals('c2'));
    });

    test('reorder root task above orphan child task at index 0', () {
      final child1 = Task(
        id: 'c1',
        title: 'Child 1',
        parentId: 'p1',
        sortOrder: 'a0',
        createdAt: now,
      );
      final root1 = Task(
        id: 'r1',
        title: 'Root 1',
        sortOrder: 'a1',
        createdAt: now,
      );

      final nodes = TaskHierarchyUtils.buildHierarchy([child1, root1]);
      expect(nodes[0].task?.id, equals('c1'));
      expect(nodes[1].task?.id, equals('r1'));

      final newRank = TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: root1,
        newIndex: 0,
        settings: settings,
        isPlanView: true,
      );
      expect(newRank, isNotNull);

      final list = [child1, root1.copyWith(planSortOrder: newRank!)];
      TaskSortUtils.sortTasks(list, settings, isPlanView: true);
      expect(list.first.id, equals('r1'));
    });

    test('allows reordering across deadline boundary in plan view', () {
      const deadlineSettings = SettingsState({'prioritize_deadlines': 'true'});
      final child1 = Task(
        id: 'c1',
        title: 'Child 1',
        parentId: 'p1',
        sortOrder: 'a0',
        deadline: DateTime(2026, 10, 20),
        createdAt: now,
      );
      final root1 = Task(
        id: 'r1',
        title: 'Root 1',
        sortOrder: 'a1',
        createdAt: now,
      );

      // In plan view, deadline difference must NOT block the drop.
      final nodes = TaskHierarchyUtils.buildHierarchy([child1, root1]);
      final isValid = TaskHierarchyReorderUtils.isPositionValidInNodes(
        draggedTask: root1,
        targetIndex: 0,
        nodes: nodes,
        settings: deadlineSettings,
        isPlanView: true,
      );
      expect(isValid, isTrue);

      final newRank = TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: root1,
        newIndex: 0,
        settings: deadlineSettings,
        isPlanView: true,
      );
      expect(newRank, isNotNull);

      final list = [child1, root1.copyWith(planSortOrder: newRank!)];
      TaskSortUtils.sortTasks(list, deadlineSettings, isPlanView: true);
      expect(list.first.id, equals('r1'));
    });

    test('reorder task above orphan child at index 1 with distinct ranks', () {
      final taskX = Task(
        id: 'tx',
        title: 'Task X',
        sortOrder: 'a0',
        createdAt: now,
      );
      final child1 = Task(
        id: 'c1',
        title: 'Child 1',
        parentId: 'p1',
        sortOrder: 'a1',
        createdAt: now,
      );
      final root1 = Task(
        id: 'r1',
        title: 'Root 1',
        sortOrder: 'a2',
        createdAt: now,
      );

      final nodes = TaskHierarchyUtils.buildHierarchy([taskX, child1, root1]);
      final newRank = TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: root1,
        newIndex: 1, // above child1 (index 1)
        settings: settings,
        isPlanView: true,
      );
      expect(newRank, isNotNull);

      final list = [taskX, child1, root1.copyWith(planSortOrder: newRank!)];
      TaskSortUtils.sortTasks(list, settings, isPlanView: true);
      expect(list[0].id, equals('tx'));
      expect(list[1].id, equals('r1'));
      expect(list[2].id, equals('c1'));
    });
  });
}
