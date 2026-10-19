import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/task_sort_utils.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderEngine Overdue Boundary & PrioritizeOverdue Tests', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    const settingsOverdueOn = SettingsState({
      SettingsConstants.keyPrioritizeOverdue: 'true',
    });
    const settingsOverdueOff = SettingsState({
      SettingsConstants.keyPrioritizeOverdue: 'false',
    });

    final urgentTask = Task(
      id: 'u1',
      title: 'Urgent Task',
      isUrgent: true,
      sortOrder: 'a0',
      planSortOrder: 'a0',
      createdAt: now,
    );
    final overdueTask = Task(
      id: 'o1',
      title: 'Overdue Task',
      deadline: yesterday,
      sortOrder: 'a1',
      planSortOrder: 'a1',
      createdAt: now,
    );
    final todayTask = Task(
      id: 't1',
      title: 'Today Task',
      scheduledDate: now,
      sortOrder: 'a2',
      planSortOrder: 'a2',
      createdAt: now,
    );

    test(
      'TaskSortUtils places overdue tasks above today tasks in plan view when enabled',
      () {
        final tasks = [todayTask, overdueTask];
        TaskSortUtils.sortTasks(tasks, settingsOverdueOn, isPlanView: true);
        expect(tasks.first.id, 'o1');
        expect(tasks.last.id, 't1');
      },
    );

    test(
      'TaskSortUtils respects planSortOrder when prioritizeOverdue is disabled',
      () {
        final tasks = [
          todayTask.copyWith(planSortOrder: 'a0'),
          overdueTask.copyWith(planSortOrder: 'a1'),
        ];
        TaskSortUtils.sortTasks(tasks, settingsOverdueOff, isPlanView: true);
        expect(tasks.first.id, 't1');
        expect(tasks.last.id, 'o1');
      },
    );

    test(
      'inSameGroup isolates overdue from normal tasks in plan view when enabled',
      () {
        final nodes = TaskHierarchyUtils.buildHierarchy([
          overdueTask,
          todayTask,
        ]);
        final sameWhenOn = TaskReorderEngine.inSameGroup(
          overdueTask,
          todayTask,
          settingsOverdueOn,
          isPlanView: true,
          nodes: nodes,
        );
        expect(sameWhenOn, isFalse);

        final sameWhenOff = TaskReorderEngine.inSameGroup(
          overdueTask,
          todayTask,
          settingsOverdueOff,
          isPlanView: true,
          nodes: nodes,
        );
        expect(sameWhenOff, isTrue);
      },
    );

    test(
      'resolveSlot clamps today task below overdue task when prioritizeOverdue is enabled',
      () {
        final nodes = TaskHierarchyUtils.buildHierarchy([
          urgentTask,
          overdueTask,
          todayTask,
        ]);

        // Attempt to drag todayTask to top slot 0
        final slotOn = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: todayTask,
          rawIndex: 0,
          settings: settingsOverdueOn,
          isPlanView: true,
        );
        // urgentTask is at 0, overdueTask is at 1 -> overdueEnd is 2
        expect(slotOn.index, 2);
        expect(slotOn.isValid, isTrue);

        // When prioritizeOverdue is off, todayTask can drag up to urgentEnd (1)
        final slotOff = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: todayTask,
          rawIndex: 0,
          settings: settingsOverdueOff,
          isPlanView: true,
        );
        expect(slotOff.index, 1);
        expect(slotOff.isValid, isTrue);
      },
    );

    test(
      'resolveSlot clamps overdue task within overdue section when enabled',
      () {
        final nodes = TaskHierarchyUtils.buildHierarchy([
          urgentTask,
          overdueTask,
          todayTask,
        ]);

        // Attempt to drag overdueTask above urgentTask (to index 0)
        final slotAbove = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: overdueTask,
          rawIndex: 0,
          settings: settingsOverdueOn,
          isPlanView: true,
        );
        expect(slotAbove.index, 1);

        // Attempt to drag overdueTask to bottom (index 3)
        final slotBelow = TaskReorderEngine.resolveSlot(
          nodes: nodes,
          draggedTask: overdueTask,
          rawIndex: 3,
          settings: settingsOverdueOn,
          isPlanView: true,
        );
        // Clamped to overdueEnd which is 2
        expect(slotBelow.index, 2);
      },
    );

    test(
      'handleReorder reorders within overdue section when prioritizeOverdue is enabled',
      () {
        final overdueTask2 = Task(
          id: 'o2',
          title: 'Overdue Task 2',
          deadline: yesterday,
          sortOrder: 'a3',
          planSortOrder: 'a3',
          createdAt: now,
        );
        final nodes = TaskHierarchyUtils.buildHierarchy([
          overdueTask,
          overdueTask2,
          todayTask,
        ]);

        final newRank = TaskReorderUtils.handleReorder(
          nodes: nodes,
          draggedTask: overdueTask2,
          newIndex: 0,
          settings: settingsOverdueOn,
          isPlanView: true,
        );
        expect(newRank, isNotNull);
        expect(newRank!.compareTo(overdueTask.planSortOrder!), lessThan(0));
      },
    );
  });
}
