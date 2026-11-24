import 'package:carpe_diem/features/common/presentation/widgets/chip/chip.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/widget_test_notifiers.dart';

void main() {
  testWidgets(
    'task chips show overdue, status, project, deadline, schedule and blocker',
    (tester) async {
      final today = DateTime(2026, 6, 10);
      // Why: const constructors only run when built non-const.
      final blocker = ['Dependency'].first;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsProvider.overrideWith(TestSettingsNotifier.new)],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const OverdueChip(),
                  StatusChip(
                    task: Task(
                      id: 'review',
                      title: 'Review',
                      status: TaskStatus.review,
                      createdAt: today,
                    ),
                  ),
                  ProjectChip(
                    project: Project(
                      id: 'project',
                      name: 'Project',
                      color: Colors.blue,
                      createdAt: today,
                    ),
                  ),
                  const ProjectChip(project: null),
                  DeadlineChip(
                    deadline: today.subtract(const Duration(days: 3)),
                    today: today,
                  ),
                  DeadlineChip(
                    deadline: today.subtract(const Duration(days: 1)),
                    today: today,
                  ),
                  DeadlineChip(deadline: today, today: today),
                  DeadlineChip(
                    deadline: today.add(const Duration(days: 1)),
                    today: today,
                  ),
                  DeadlineChip(
                    deadline: today.add(const Duration(days: 3)),
                    today: today,
                  ),
                  DeadlineChip(
                    deadline: today.add(const Duration(days: 5)),
                    today: today,
                  ),
                  DeadlineChip(
                    deadline: today,
                    today: today,
                    isCompleted: true,
                  ),
                  ScheduledChip(scheduledDate: DateTime.now()),
                  ScheduledChip(
                    scheduledDate: DateTime.now().add(const Duration(days: 1)),
                  ),
                  ScheduledChip(scheduledDate: DateTime(2030, 3, 4)),
                  BlockedChip(blockerTitle: blocker),
                  const BlockedChip(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Overdue by 3 days'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Due tomorrow'), findsOneWidget);
      expect(find.text('Due in 3 days'), findsOneWidget);
      expect(find.text('Due in 5 days'), findsOneWidget);
    },
  );
}
