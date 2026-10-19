import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderUtils Dispatch & Multi-Reorder Validation', () {
    final now = DateTime.now();
    const settings = SettingsState({});

    final urgent1 = Task(
      id: 'u1',
      title: 'Urgent 1',
      isUrgent: true,
      sortOrder: 'a0',
      createdAt: now,
    );
    final normal1 = Task(
      id: 'n1',
      title: 'Normal 1',
      isUrgent: false,
      sortOrder: 'a1',
      createdAt: now,
    );
    final normal2 = Task(
      id: 'n2',
      title: 'Normal 2',
      isUrgent: false,
      sortOrder: 'a2',
      createdAt: now,
    );
    final normal3 = Task(
      id: 'n3',
      title: 'Normal 3',
      isUrgent: false,
      sortOrder: 'a3',
      createdAt: now,
    );

    final subtask1 = Task(
      id: 's1',
      title: 'Subtask 1',
      parentId: 'p1',
      sortOrder: 'a0',
      createdAt: now,
    );
    final subtask2 = Task(
      id: 's2',
      title: 'Subtask 2',
      parentId: 'p2',
      sortOrder: 'a1',
      createdAt: now,
    );

    test('dispatchReorder routes to onReorder for single task', () {
      final nodes = [TaskNode(normal1, 0), TaskNode(normal2, 0)];
      Task? reorderedTask;
      String? newOrder;

      final dispatched = TaskReorderUtils.dispatchReorder(
        nodes: nodes,
        draggedTask: normal2,
        newIndex: 0,
        settings: settings,
        onReorder: (task, order) {
          reorderedTask = task;
          newOrder = order;
        },
      );

      expect(dispatched, isTrue);
      expect(reorderedTask?.id, 'n2');
      expect(newOrder, isNotNull);
    });

    test('dispatchReorder routes to onMultiReorder when task is selected', () {
      final nodes = [
        TaskNode(normal1, 0),
        TaskNode(normal2, 0),
        TaskNode(normal3, 0),
      ];
      Map<String, String>? multiOrders;

      final dispatched = TaskReorderUtils.dispatchReorder(
        nodes: nodes,
        draggedTask: normal2,
        newIndex: 0,
        selectedTaskIds: {'n2', 'n3'},
        settings: settings,
        onMultiReorder: (orders) => multiOrders = orders,
      );

      expect(dispatched, isTrue);
      expect(multiOrders?.keys, containsAll(['n2', 'n3']));
    });

    test('handleMultiReorder rejects heterogeneous group selections', () {
      final nodes = [
        TaskNode(urgent1, 0),
        TaskNode(normal1, 0),
        TaskNode(normal2, 0),
      ];

      // Multi-selection spanning urgent and non-urgent tasks
      final result = TaskReorderUtils.handleMultiReorder(
        nodes: nodes,
        draggedTask: normal1,
        newIndex: 0,
        selectedTaskIds: {'u1', 'n1'},
        settings: settings,
      );

      expect(result, isNull);
    });

    test('handleMultiReorder rejects subtasks across different parents', () {
      final nodes = [TaskNode(subtask1, 0), TaskNode(subtask2, 0)];

      final result = TaskReorderUtils.handleMultiReorder(
        nodes: nodes,
        draggedTask: subtask1,
        newIndex: 1,
        selectedTaskIds: {'s1', 's2'},
        settings: settings,
      );

      expect(result, isNull);
    });
  });
}
