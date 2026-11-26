import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/bulk_planning_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_notifiers.dart';

void main() {
  testWidgets('bulk planning bar invokes actions and disables mixed grouping', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final one = Task(
      id: 'one',
      title: 'One',
      projectId: 'p1',
      createdAt: DateTime(2026),
    );
    final two = Task(
      id: 'two',
      title: 'Two',
      projectId: 'p2',
      createdAt: DateTime(2026),
    );
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProvider.overrideWith(
            () => TestTaskNotifier(
              TaskState(currentDate: DateTime(2026), tasks: [one, two]),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BulkPlanningBar(
              selectedTaskIds: const ['one', 'two'],
              onClearSelection: () => calls++,
              onScheduleToday: () => calls++,
              onScheduleTomorrow: () => calls++,
              onBulkEdit: () => calls++,
              onBulkDelete: () => calls++,
              onGroupTasks: () => calls++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2 tasks selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear selection'));
    await tester.tap(find.text('Today'));
    await tester.tap(find.text('Tomorrow'));
    await tester.tap(find.text('Edit'));
    await tester.tap(find.text('Delete'));
    expect(calls, 5);
    final group = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Group'),
    );
    expect(group.onPressed, isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProvider.overrideWith(
            () => TestTaskNotifier(
              TaskState(currentDate: DateTime(2026), tasks: [one]),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BulkPlanningBar(
              selectedTaskIds: const ['one'],
              onClearSelection: () {},
              onScheduleToday: () {},
              onScheduleTomorrow: () {},
              onBulkEdit: () {},
              onBulkDelete: () {},
              onGroupTasks: () => calls++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Group'));
    expect(calls, 6);
  });

  testWidgets(
    'bulk planning bar hides empty selection and disables scheduling',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskProvider.overrideWith(
              () => TestTaskNotifier(TaskState(currentDate: DateTime(2026))),
            ),
          ],
          child: MaterialApp(
            home: Column(
              children: [
                BulkPlanningBar(
                  selectedTaskIds: const [],
                  onClearSelection: () {},
                  onScheduleToday: () {},
                  onScheduleTomorrow: () {},
                  onBulkEdit: () {},
                  onBulkDelete: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.textContaining('selected'), findsNothing);
    },
  );
}
