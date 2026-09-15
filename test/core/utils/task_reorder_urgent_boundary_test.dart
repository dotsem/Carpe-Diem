import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderUtils urgent boundary reordering', () {
    final now = DateTime.now();
    const settings = SettingsState({});

    final urgent1 = Task(
      id: 'u1',
      title: 'Urgent 1',
      isUrgent: true,
      createdAt: now,
      sortOrder: 'a0',
    );
    final urgent2 = Task(
      id: 'u2',
      title: 'Urgent 2',
      isUrgent: true,
      createdAt: now,
      sortOrder: 'a1',
    );
    final normal1 = Task(
      id: 'n1',
      title: 'Normal 1',
      isUrgent: false,
      createdAt: now,
      sortOrder: 'a2',
    );
    final normal2 = Task(
      id: 'n2',
      title: 'Normal 2',
      isUrgent: false,
      createdAt: now,
      sortOrder: 'a3',
    );

    test('getUrgentSectionEndIndex correctly identifies boundary', () {
      final mixedNodes = [
        TaskNode(urgent1, 0),
        TaskNode(urgent2, 0),
        TaskNode(normal1, 0),
        TaskNode(normal2, 0),
      ];
      expect(TaskReorderUtils.getUrgentSectionEndIndex(mixedNodes), 2);

      final allUrgent = [TaskNode(urgent1, 0), TaskNode(urgent2, 0)];
      expect(TaskReorderUtils.getUrgentSectionEndIndex(allUrgent), 2);

      final noUrgent = [TaskNode(normal1, 0), TaskNode(normal2, 0)];
      expect(TaskReorderUtils.getUrgentSectionEndIndex(noUrgent), 0);
    });

    test('getUrgentSectionEndIndex accounts for bundled subtasks', () {
      final subtask = Task(
        id: 's1',
        title: 'Subtask of Urgent',
        parentId: 'u1',
        createdAt: now,
        sortOrder: 's0',
      );
      final nodes = [
        TaskNode(urgent1, 0),
        TaskNode(subtask, 1, isBundledUnderParent: true),
        TaskNode(normal1, 0),
      ];
      expect(TaskReorderUtils.getUrgentSectionEndIndex(nodes), 2);
    });

    test(
      'handleReorder clamps non-urgent drop above or inside urgent section',
      () {
        final nodes = [
          TaskNode(urgent1, 0),
          TaskNode(urgent2, 0),
          TaskNode(normal1, 0),
          TaskNode(normal2, 0),
        ];

        // Dropping normal2 at index 0 (above urgent1)
        final sortOrderAtTop = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: normal2,
          newIndex: 0,
          settings: settings,
        );

        // Clamped to index 2 (top of non-urgent section, before normal1)
        expect(sortOrderAtTop, isNotNull);
        expect(sortOrderAtTop!.compareTo(normal1.sortOrder), lessThan(0));

        // Dropping normal2 at index 1 (between urgent1 and urgent2)
        final sortOrderMidUrgent = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: normal2,
          newIndex: 1,
          settings: settings,
        );

        // Clamped to index 2 (top of non-urgent section, before normal1)
        expect(sortOrderMidUrgent, isNotNull);
        expect(sortOrderMidUrgent!.compareTo(normal1.sortOrder), lessThan(0));
      },
    );

    test('handleReorder clamps urgent drop below urgent section', () {
      final nodes = [
        TaskNode(urgent1, 0),
        TaskNode(urgent2, 0),
        TaskNode(normal1, 0),
        TaskNode(normal2, 0),
      ];

      // Dropping urgent1 at index 3 (between normal1 and normal2)
      final sortOrder = TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: urgent1,
        newIndex: 3,
        settings: settings,
      );

      // Clamped to urgent section boundary (bottom of urgent section, after urgent2)
      expect(sortOrder, isNotNull);
      expect(sortOrder!.compareTo(urgent2.sortOrder), greaterThan(0));
    });

    test(
      'handleReorder allows normal reordering within same urgency section',
      () {
        final nodes = [
          TaskNode(urgent1, 0),
          TaskNode(urgent2, 0),
          TaskNode(normal1, 0),
          TaskNode(normal2, 0),
        ];

        // Moving urgent2 to top (index 0)
        final urgentToTop = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: urgent2,
          newIndex: 0,
          settings: settings,
        );
        expect(urgentToTop, isNotNull);
        expect(urgentToTop!.compareTo(urgent1.sortOrder), lessThan(0));

        // Moving normal1 to bottom (index 4)
        final normalToBottom = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: normal1,
          newIndex: 4,
          settings: settings,
        );
        expect(normalToBottom, isNotNull);
        expect(normalToBottom!.compareTo(normal2.sortOrder), greaterThan(0));
      },
    );

    test('dragging between bottom urgent and top normal with base62 rank', () {
      final u = Task(
        id: 'u',
        title: 'U',
        isUrgent: true,
        createdAt: now,
        sortOrder: 'a0',
      );
      final n1 = Task(
        id: 'n1',
        title: 'N1',
        isUrgent: false,
        createdAt: now,
        sortOrder: 'a8',
      );
      final n2 = Task(
        id: 'n2',
        title: 'N2',
        isUrgent: false,
        createdAt: now,
        sortOrder: 'aG',
      );

      final listNodes = [TaskNode(u, 0), TaskNode(n1, 0), TaskNode(n2, 0)];

      final res = TaskReorderUtils.handleReorder(
        nodes: listNodes,
        draggedTask: n2,
        newIndex: 1,
        settings: settings,
      );

      expect(res, isNotNull);
      expect(res!.compareTo(n1.sortOrder), lessThan(0));
    });

    test(
      'dragging below parent container with urgent child places task before top normal',
      () {
        final parent = Task(
          id: 'p',
          title: 'Parent',
          isUrgent: false,
          createdAt: now,
          sortOrder: 'a0',
        );
        final parentNode = ParentContainerNode(
          task: parent,
          depth: 0,
          totalSubtasks: 1,
          completedSubtasks: 0,
          plannedSubtasks: 0,
          hasUrgentChild: true,
          isCollapsed: false,
        );
        final n1 = Task(
          id: 'n1',
          title: 'N1',
          isUrgent: false,
          createdAt: now,
          sortOrder: 'a2',
        );
        final n2 = Task(
          id: 'n2',
          title: 'N2',
          isUrgent: false,
          createdAt: now,
          sortOrder: 'a4',
        );

        final listNodes = [parentNode, TaskNode(n1, 0), TaskNode(n2, 0)];

        final res = TaskReorderUtils.handleReorder(
          nodes: listNodes,
          draggedTask: n2,
          newIndex: 1,
          settings: settings,
        );

        expect(res, isNotNull);
        expect(res!.compareTo(n1.sortOrder), lessThan(0));
      },
    );
  });
}
