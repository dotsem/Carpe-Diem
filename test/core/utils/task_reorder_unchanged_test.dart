import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/task_test_helpers.dart';

void main() {
  group('TaskReorderUtils unchanged position tests', () {
    const settings = SettingsState({});

    final u1 = createTestTask(id: 'u1', isUrgent: true, sortOrder: 'a0');
    final u2 = createTestTask(id: 'u2', isUrgent: true, sortOrder: 'a1');
    final n1 = createTestTask(id: 'n1', sortOrder: 'a2');
    final n2 = createTestTask(id: 'n2', sortOrder: 'a3');
    final n3 = createTestTask(id: 'n3', sortOrder: 'a4');

    final listNodes = [
      TaskNode(u1, 0),
      TaskNode(u2, 0),
      TaskNode(n1, 0),
      TaskNode(n2, 0),
      TaskNode(n3, 0),
    ];

    test('handleReorder returns null when dropped on self or next slot', () {
      final resSame = TaskReorderUtils.handleReorder(
        nodes: listNodes,
        draggedTask: n2,
        newIndex: 3,
        settings: settings,
      );
      expect(resSame, isNull);

      final resNext = TaskReorderUtils.handleReorder(
        nodes: listNodes,
        draggedTask: n2,
        newIndex: 4,
        settings: settings,
      );
      expect(resNext, isNull);
    });

    test(
      'handleReorder returns new sort order when moved to different slot',
      () {
        final resMoved = TaskReorderUtils.handleReorder(
          nodes: listNodes,
          draggedTask: n2,
          newIndex: 2,
          settings: settings,
        );
        expect(resMoved, isNotNull);
        expect(resMoved!.compareTo(n1.sortOrder), lessThan(0));

        final resMovedDown = TaskReorderUtils.handleReorder(
          nodes: listNodes,
          draggedTask: n2,
          newIndex: 5,
          settings: settings,
        );
        expect(resMovedDown, isNotNull);
        expect(resMovedDown!.compareTo(n3.sortOrder), greaterThan(0));
      },
    );

    test('handleReorder returns null when clamped to same position', () {
      final resClamped = TaskReorderUtils.handleReorder(
        nodes: listNodes,
        draggedTask: u2,
        newIndex: 3,
        settings: settings,
      );
      expect(resClamped, isNull);
    });

    test(
      'handleMultiReorder returns null when selected group position unchanged',
      () {
        final resSameSlot2 = TaskReorderUtils.handleMultiReorder(
          nodes: listNodes,
          draggedTask: n1,
          newIndex: 2,
          selectedTaskIds: {'n1', 'n2'},
          settings: settings,
        );
        expect(resSameSlot2, isNull);

        final resSameSlot3 = TaskReorderUtils.handleMultiReorder(
          nodes: listNodes,
          draggedTask: n1,
          newIndex: 3,
          selectedTaskIds: {'n1', 'n2'},
          settings: settings,
        );
        expect(resSameSlot3, isNull);
      },
    );

    test('handleMultiReorder returns new ranks when moved to new slot', () {
      final resMoved = TaskReorderUtils.handleMultiReorder(
        nodes: listNodes,
        draggedTask: n1,
        newIndex: 5,
        selectedTaskIds: {'n1', 'n2'},
        settings: settings,
      );
      expect(resMoved, isNotNull);
      expect(resMoved!.length, 2);
      expect(resMoved['n1']!.compareTo(n3.sortOrder), greaterThan(0));
      expect(resMoved['n2']!.compareTo(resMoved['n1']!), greaterThan(0));
    });
  });
}
