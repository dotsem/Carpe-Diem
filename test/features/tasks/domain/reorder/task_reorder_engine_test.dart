import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_slot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  const settings = SettingsState({});

  group('getOverdueSectionEndIndex', () {
    test('spans every node when all of them are overdue', () {
      final nodes = [
        TaskNode(createTestTask(id: 'a', deadline: DateTime(2000)), 0),
        TaskNode(createTestTask(id: 'b', deadline: DateTime(2000)), 0),
      ];

      expect(TaskReorderEngine.getOverdueSectionEndIndex(nodes, 0), 2);
    });
  });

  group('computeRanks for a task alone in its group', () {
    const slot = TaskReorderSlot(index: 1, isValid: true, isUnchanged: false);

    test('assigns the default rank when it has none yet', () {
      final only = createTestTask(id: 'only');

      final ranks = TaskReorderEngine.computeRanks(
        nodes: [TaskNode(only, 0)],
        draggedTask: only,
        slot: slot,
        settings: settings.taskPrefs,
      );

      expect(ranks, {'only': LexoRank.defaultRank});
    });

    test('keeps an existing plan rank untouched in plan view', () {
      final only = createTestTask(id: 'only').copyWith(planSortOrder: 'p1');

      final ranks = TaskReorderEngine.computeRanks(
        nodes: [TaskNode(only, 0)],
        draggedTask: only,
        slot: slot,
        settings: settings.taskPrefs,
        isPlanView: true,
      );

      expect(ranks, isNull);
    });
  });
}
