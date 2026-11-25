import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderEngine hierarchy', () {
    final now = DateTime.now();
    final urgentA = Task(
      id: 'u1',
      title: 'Urgent 1',
      isUrgent: true,
      createdAt: now,
    );
    final normalB = Task(id: 'n1', title: 'Normal 1', createdAt: now);
    final deadlineC = Task(
      id: 'd1',
      title: 'Deadline 1',
      deadline: DateTime(2026, 10, 20),
      createdAt: now,
    );

    final nodes = <TaskHierarchyNode>[
      TaskNode(urgentA, 0),
      TaskNode(normalB, 0),
      TaskNode(deadlineC, 0),
    ];

    const defaultSettings = SettingsState({});
    const deadlineSettings = SettingsState({'prioritize_deadlines': 'true'});

    test('isPositionInGroup validates urgency boundaries', () {
      expect(
        TaskReorderEngine.isPositionInGroup(
          draggedTask: urgentA,
          targetIndex: 0,
          nodes: nodes,
          settings: defaultSettings.taskPrefs,
        ),
        isTrue,
      );
      expect(
        TaskReorderEngine.isPositionInGroup(
          draggedTask: urgentA,
          targetIndex: 1,
          nodes: nodes,
          settings: defaultSettings.taskPrefs,
        ),
        isTrue,
      );
      expect(
        TaskReorderEngine.isPositionInGroup(
          draggedTask: urgentA,
          targetIndex: 2,
          nodes: nodes,
          settings: defaultSettings.taskPrefs,
        ),
        isFalse,
      );
    });

    test('isPositionInGroup respects plan view deadline bypass', () {
      expect(
        TaskReorderEngine.isPositionInGroup(
          draggedTask: normalB,
          targetIndex: 3,
          nodes: nodes,
          settings: deadlineSettings.taskPrefs,
        ),
        isFalse,
      );
      expect(
        TaskReorderEngine.isPositionInGroup(
          draggedTask: normalB,
          targetIndex: 3,
          nodes: nodes,
          settings: deadlineSettings.taskPrefs,
          isPlanView: true,
        ),
        isTrue,
      );
    });
  });
}
