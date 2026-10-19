import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_scroll_view.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskReorder Drop Target Single Fire & Fallback Tests', () {
    late TestTaskRepositories repos;
    final now = DateTime.now();
    final task1 = Task(
      id: 't1',
      title: 'Task 1',
      sortOrder: 'a0',
      createdAt: now,
    );
    final task2 = Task(
      id: 't2',
      title: 'Task 2',
      sortOrder: 'a1',
      createdAt: now,
    );

    setUpAll(() {
      registerFallbackValue(task1);
    });

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    testWidgets('top padding drop target triggers drop exactly once', (
      tester,
    ) async {
      final nodes = [TaskNode(task1, 0), TaskNode(task2, 0)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskListScrollView(
                activeNodes: nodes,
                activeWidgets: const [
                  SizedBox(height: 50, child: Text('Card 1')),
                  SizedBox(height: 50, child: Text('Card 2')),
                ],
                doneWidgets: const [],
                doneCount: 0,
                isDoneExpanded: false,
                onToggleDone: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final topDropFinder = find
          .byWidgetPredicate((w) => w is DragTarget<Task>)
          .first;
      final topDrop = tester.widget<DragTarget<Task>>(topDropFinder);

      when(() => repos.mockTaskRepo.update(any())).thenAnswer((_) async {});

      final details = DragTargetDetails<Task>(data: task2, offset: Offset.zero);
      topDrop.onAcceptWithDetails?.call(details);
      await tester.pumpAndSettle();

      verify(() => repos.mockTaskRepo.update(any())).called(1);
    });

    testWidgets(
      'handleDragEnd triggers fallback drop when wasAccepted is false',
      (tester) async {
        final nodes = [TaskNode(task1, 0), TaskNode(task2, 0)];
        int fallbackDropCount = 0;
        Task? fallbackTask;
        int? fallbackIndex;

        await tester.pumpWidget(
          ProviderScope(
            overrides: repos.providerOverrides,
            child: MaterialApp(
              home: Scaffold(
                body: TaskReorderScope(
                  nodes: nodes,
                  onDrop: (_, _) {},
                  child: Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          final scope = TaskReorderScope.of(context);
                          scope?.onHoverSlot(task2, 0);
                          scope?.handleDragEnd(
                            DraggableDetails(
                              wasAccepted: false,
                              velocity: Velocity.zero,
                              offset: Offset.zero,
                            ),
                            onFallbackDrop: (t, idx) {
                              fallbackDropCount++;
                              fallbackTask = t;
                              fallbackIndex = idx;
                            },
                          );
                        },
                        child: const Text('Test Fallback'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Test Fallback'));
        await tester.pump();
        await tester.pump();

        expect(fallbackDropCount, 1);
        expect(fallbackTask?.id, 't2');
        expect(fallbackIndex, 0);
      },
    );
  });
}
