import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_column.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_column_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_done_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskReorder Edge Drop Targets', () {
    late TestTaskRepositories repos;
    final now = DateTime.now();
    final task1 = Task(id: 't1', title: 'Task 1', createdAt: now);
    final task2 = Task(id: 't2', title: 'Task 2', createdAt: now);

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    testWidgets('collapsed TaskListDoneSection routes drop to bottom index', (
      tester,
    ) async {
      final nodes = [TaskNode(task1, 0), TaskNode(task2, 0)];
      int? droppedIndex;
      Task? droppedTask;

      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskReorderScope(
                nodes: nodes,
                onDrop: (task, index) {
                  droppedTask = task;
                  droppedIndex = index;
                },
                child: TaskListDoneSection(
                  count: 1,
                  isExpanded: false,
                  onToggle: () {},
                  children: const [],
                ),
              ),
            ),
          ),
        ),
      );

      final dragTargetFinder = find.descendant(
        of: find.byType(TaskListDoneSection),
        matching: find.byType(DragTarget<Task>),
      );
      expect(dragTargetFinder, findsOneWidget);

      final dragTarget = tester.widget<DragTarget<Task>>(dragTargetFinder);
      final details = DragTargetDetails<Task>(data: task1, offset: Offset.zero);

      final willAccept = dragTarget.onWillAcceptWithDetails?.call(details);
      expect(willAccept, isTrue);

      dragTarget.onAcceptWithDetails?.call(details);
      await tester.pump();

      expect(droppedTask?.id, 't1');
      expect(droppedIndex, 2);
    });

    testWidgets('KanbanColumnHeader routes drop to top index 0', (
      tester,
    ) async {
      final nodes = [TaskNode(task1, 0), TaskNode(task2, 0)];
      int? droppedIndex;
      Task? droppedTask;

      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskReorderScope(
                nodes: nodes,
                onDrop: (task, index) {
                  droppedTask = task;
                  droppedIndex = index;
                },
                child: const KanbanColumnHeader(
                  title: 'To Do',
                  titleColor: Colors.blue,
                  count: 2,
                ),
              ),
            ),
          ),
        ),
      );

      final dragTargetFinder = find.descendant(
        of: find.byType(KanbanColumnHeader),
        matching: find.byType(DragTarget<Task>),
      );
      expect(dragTargetFinder, findsOneWidget);

      final dragTarget = tester.widget<DragTarget<Task>>(dragTargetFinder);
      final details = DragTargetDetails<Task>(data: task2, offset: Offset.zero);

      final willAccept = dragTarget.onWillAcceptWithDetails?.call(details);
      expect(willAccept, isTrue);

      dragTarget.onAcceptWithDetails?.call(details);
      await tester.pump();

      expect(droppedTask?.id, 't2');
      expect(droppedIndex, 0);
    });

    testWidgets(
      'KanbanColumn highlights only for foreign-status tasks and resets',
      (tester) async {
        final foreignTask = Task(
          id: 't_foreign',
          title: 'Foreign Task',
          status: TaskStatus.todo,
          createdAt: now,
        );
        final sameStatusTask = Task(
          id: 't_same',
          title: 'Same Status Task',
          status: TaskStatus.inProgress,
          createdAt: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: repos.providerOverrides,
            child: MaterialApp(
              home: Scaffold(
                body: Row(
                  children: [
                    Draggable<Task>(
                      data: foreignTask,
                      feedback: const Text('Dragging Foreign'),
                      child: const Text('Source Foreign'),
                    ),
                    Draggable<Task>(
                      data: sameStatusTask,
                      feedback: const Text('Dragging Same'),
                      child: const Text('Source Same'),
                    ),
                    Expanded(
                      child: KanbanColumn(
                        title: 'In Progress',
                        titleColor: Colors.amber,
                        tasks: [sameStatusTask],
                        acceptedStatus: TaskStatus.inProgress,
                        onStatusChange: (_, _) {},
                        onContextMenu: (_, _, _) {},
                        onEdit: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Border getColumnBorder() {
          final animatedContainer = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(KanbanColumn),
              matching: find.byType(AnimatedContainer),
            ),
          );
          final decoration = animatedContainer.decoration as BoxDecoration;
          return decoration.border as Border;
        }

        expect(getColumnBorder().top.width, 1.0);

        final foreignGesture = await tester.startGesture(
          tester.getCenter(find.text('Source Foreign')),
        );
        await tester.pump();
        await foreignGesture.moveTo(
          tester.getCenter(find.byType(KanbanColumn)),
        );
        await tester.pump();

        expect(getColumnBorder().top.width, 2.0);

        await foreignGesture.moveTo(
          tester.getCenter(find.text('Source Foreign')),
        );
        await tester.pump();
        await tester.pump();

        expect(getColumnBorder().top.width, 1.0);

        await foreignGesture.up();
        await tester.pump();

        final sameGesture = await tester.startGesture(
          tester.getCenter(find.text('Source Same')),
        );
        await tester.pump();
        await sameGesture.moveTo(tester.getCenter(find.byType(KanbanColumn)));
        await tester.pump();

        expect(getColumnBorder().top.width, 1.0);

        await sameGesture.up();
        await tester.pump();
        expect(getColumnBorder().top.width, 1.0);
      },
    );

    testWidgets('TaskReorderItem bottom slot remains stable without flicker', (
      tester,
    ) async {
      final nodes = [TaskNode(task1, 0), TaskNode(task2, 0)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskReorderScope(
                nodes: nodes,
                onDrop: (_, _) {},
                child: Column(
                  children: [
                    Draggable<Task>(
                      data: task1,
                      feedback: const Text('Dragging Task 1'),
                      child: const Text('Drag Source'),
                    ),
                    TaskReorderItem(
                      index: 0,
                      child: const SizedBox(
                        key: ValueKey('item_box_0'),
                        height: 60,
                        child: Text('Item 0 Content'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dragGesture = await tester.startGesture(
        tester.getCenter(find.text('Drag Source')),
      );
      await tester.pump();

      final boxTopLeft = tester.getTopLeft(
        find.byKey(const ValueKey('item_box_0')),
      );
      await dragGesture.moveTo(boxTopLeft + const Offset(10, 45));
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('item_box_0'))).dy,
        boxTopLeft.dy,
      );

      await dragGesture.moveTo(boxTopLeft + const Offset(10, 50));
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('item_box_0'))).dy,
        boxTopLeft.dy,
      );

      await dragGesture.up();
      await tester.pumpAndSettle();
    });
  });
}
