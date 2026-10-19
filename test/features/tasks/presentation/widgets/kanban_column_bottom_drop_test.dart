import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_column.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_empty_space_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('KanbanColumn Bottom Drop Tests', () {
    late TestTaskRepositories repos;
    final now = DateTime.now();
    final task1 = Task(
      id: 't1',
      title: 'Task 1',
      status: TaskStatus.todo,
      sortOrder: 'a0',
      planSortOrder: 'a0',
      createdAt: now,
    );
    final task2 = Task(
      id: 't2',
      title: 'Task 2',
      status: TaskStatus.todo,
      sortOrder: 'a1',
      planSortOrder: 'a1',
      createdAt: now,
    );

    setUpAll(() {
      registerFallbackValue(task1);
    });

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    testWidgets(
      'uncollapsed KanbanColumn accepts same-status drop and reorders to bottom',
      (tester) async {
        when(() => repos.mockTaskRepo.update(any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: repos.providerOverrides,
            child: MaterialApp(
              home: Scaffold(
                body: KanbanColumn(
                  title: 'To Do',
                  titleColor: Colors.blue,
                  tasks: [task1, task2],
                  acceptedStatus: TaskStatus.todo,
                  onStatusChange: (_, _) {},
                  onContextMenu: (_, _, _) {},
                  onEdit: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final outerTargetFinder = find
            .descendant(
              of: find.byType(KanbanColumn),
              matching: find.byType(DragTarget<Task>),
            )
            .first;

        final outerTarget = tester.widget<DragTarget<Task>>(outerTargetFinder);
        final details = DragTargetDetails<Task>(
          data: task1,
          offset: Offset.zero,
        );

        final willAccept = outerTarget.onWillAcceptWithDetails?.call(details);
        expect(willAccept, isTrue);

        outerTarget.onAcceptWithDetails?.call(details);
        await tester.pumpAndSettle();

        verify(() => repos.mockTaskRepo.update(any())).called(1);
      },
    );

    testWidgets('persistent TaskEmptySpaceDropZone is present in column', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: KanbanColumn(
                title: 'To Do',
                titleColor: Colors.blue,
                tasks: [task1, task2],
                acceptedStatus: TaskStatus.todo,
                onStatusChange: (_, _) {},
                onContextMenu: (_, _, _) {},
                onEdit: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TaskEmptySpaceDropZone), findsWidgets);
    });

    testWidgets('collapsed KanbanColumn rejects same-status drop', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: KanbanColumn(
                title: 'To Do',
                titleColor: Colors.blue,
                tasks: [task1, task2],
                acceptedStatus: TaskStatus.todo,
                isCollapsed: true,
                onStatusChange: (_, _) {},
                onContextMenu: (_, _, _) {},
                onEdit: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final outerTargetFinder = find
          .descendant(
            of: find.byType(KanbanColumn),
            matching: find.byType(DragTarget<Task>),
          )
          .first;

      final outerTarget = tester.widget<DragTarget<Task>>(outerTargetFinder);
      final details = DragTargetDetails<Task>(data: task1, offset: Offset.zero);

      final willAccept = outerTarget.onWillAcceptWithDetails?.call(details);
      expect(willAccept, isFalse);
    });
  });
}
