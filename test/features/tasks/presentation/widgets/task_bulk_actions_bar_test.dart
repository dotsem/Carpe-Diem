import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_bulk_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/widget_test_notifiers.dart';

class _RecordingTaskNotifier extends TestTaskNotifier {
  final deleted = <Task>[];

  _RecordingTaskNotifier(super.initial);

  @override
  Future<void> deleteTask(Task task, {bool deleteSubtasks = true}) async {
    deleted.add(task);
  }
}

void main() {
  group('TaskBulkActionsBar', () {
    final parent = Task(
      id: 'parent',
      title: 'Parent',
      createdAt: DateTime(2026),
    );
    final child = Task(
      id: 'child',
      title: 'Child',
      parentId: 'parent',
      createdAt: DateTime(2026),
    );

    Future<_RecordingTaskNotifier> pumpBar(
      WidgetTester tester, {
      required List<String> selected,
      required VoidCallback onActionCompleted,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final notifier = _RecordingTaskNotifier(
        TaskState(
          currentDate: DateTime(2026),
          unscheduledTasks: [parent, child],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(MockTaskRepository()),
            taskProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TaskBulkActionsBar(
                selectedTaskIds: selected,
                tasks: [parent, child],
                onClearSelection: () {},
                onActionCompleted: onActionCompleted,
                onScheduleToday: () {},
                onScheduleTomorrow: () {},
              ),
            ),
          ),
        ),
      );
      return notifier;
    }

    testWidgets('single delete warns about subtasks and deletes on confirm', (
      tester,
    ) async {
      var completed = 0;
      final notifier = await pumpBar(
        tester,
        selected: ['parent'],
        onActionCompleted: () => completed++,
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to delete this task and its 1 subtask?',
        ),
        findsOneWidget,
      );
      expect(notifier.deleted, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(notifier.deleted, [parent]);
      expect(completed, 1);
    });

    testWidgets('single delete of a task that left the list does nothing', (
      tester,
    ) async {
      final notifier = await pumpBar(
        tester,
        selected: ['gone'],
        onActionCompleted: () {},
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Are you sure'), findsNothing);
      expect(notifier.deleted, isEmpty);
    });
  });
}
