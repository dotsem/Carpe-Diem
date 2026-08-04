import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/complete_parent_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_breadcrumb_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/subtask_progress_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('tasks', () {
    testWidgets('SubtaskProgressChip renders completed and total count', (
      tester,
    ) async {
      bool toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskProgressChip(
              completedCount: 1,
              plannedCount: 2,
              totalCount: 3,
              isCollapsed: true,
              onToggleCollapse: () {
                toggled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byType(SubtaskProgressChip));
      expect(toggled, isTrue);
    });

    testWidgets(
      'SubtaskProgressChip renders success icon when all subtasks completed',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SubtaskProgressChip(
                completedCount: 3,
                plannedCount: 0,
                totalCount: 3,
              ),
            ),
          ),
        );

        expect(find.text('3/3'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      },
    );

    testWidgets(
      'ParentBreadcrumbHeader displays clean parent title and opens dialog on tap',
      (tester) async {
        final repos = TestTaskRepositories();
        repos.setupDefaultStubs();

        final parentTask = createTestTask(id: 'p1', title: 'Build UI #feature');
        when(
          () => repos.mockTaskRepo.getById('p1'),
        ).thenAnswer((_) async => parentTask);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              parentTaskProvider('p1').overrideWith((ref) => parentTask),
              ...repos.providerOverrides,
            ],
            child: const MaterialApp(
              home: Scaffold(body: ParentBreadcrumbHeader(parentId: 'p1')),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Build UI feature'), findsOneWidget);
        expect(
          find.byIcon(Icons.subdirectory_arrow_right_rounded),
          findsOneWidget,
        );

        await tester.tap(find.byType(ParentBreadcrumbHeader));
        await tester.pumpAndSettle();

        expect(find.byType(ParentBreadcrumbHeader), findsOneWidget);
      },
    );

    testWidgets(
      'CompleteParentDialog displays conflict message and action buttons',
      (tester) async {
        final repos = TestTaskRepositories();
        repos.setupDefaultStubs();

        final parentTask = createTestTask(
          id: 'p1',
          title: 'Parent',
          status: TaskStatus.inProgress,
        );
        final subtask = createTestTask(
          id: 's1',
          title: 'Sub',
          parentId: 'p1',
          status: TaskStatus.todo,
        );

        final conflict = SubtaskCompletionConflict(
          parentTask: parentTask,
          incompleteSubtasks: [subtask],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: repos.providerOverrides,
            child: MaterialApp(
              home: Scaffold(body: CompleteParentDialog(conflict: conflict)),
            ),
          ),
        );

        expect(find.text('Complete Parent Task?'), findsOneWidget);
        expect(
          find.text('"Parent" has 1 incomplete subtask is still remaining.'),
          findsOneWidget,
        );
        expect(find.text('Complete parent only'), findsOneWidget);
        expect(find.text('Complete all'), findsOneWidget);
      },
    );
  });
}
