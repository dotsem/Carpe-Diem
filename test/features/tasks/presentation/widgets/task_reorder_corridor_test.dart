import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone_scope.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_empty_space_drop_zone.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_reorder_corridor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskReorderCorridor & TaskEmptySpaceDropZone', () {
    final now = DateTime.now();
    final task1 = Task(id: 't1', title: 'Task 1', createdAt: now);
    final task2 = Task(id: 't2', title: 'Task 2', createdAt: now);
    final nodes = [TaskNode(task1, 0), TaskNode(task2, 0)];

    Widget buildTestHarness({
      required ScrollController scrollController,
      required void Function(Task, int) onDrop,
      required ProviderContainer container,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 400,
                child: TaskDropZoneScope(
                  urgentSectionEndIndex: 0,
                  itemCount: nodes.length,
                  resolveClampedTopIndex: (task) => 0,
                  resolveClampedBottomIndex: (task) => nodes.length,
                  onDrop: onDrop,
                  child: TaskReorderCorridor(
                    scrollController: scrollController,
                    nodes: nodes,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onDrop: onDrop,
                    child: Column(
                      children: [
                        Container(height: 100, color: Colors.blue),
                        Expanded(child: TaskEmptySpaceDropZone(onDrop: onDrop)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Corridor gates horizontal pointer movements and triggers top drop on release',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final controller = ScrollController();
        addTearDown(controller.dispose);

        Task? droppedTask;
        int? droppedIndex;

        await tester.pumpWidget(
          buildTestHarness(
            scrollController: controller,
            onDrop: (task, index) {
              droppedTask = task;
              droppedIndex = index;
            },
            container: container,
          ),
        );

        final corridorFinder = find.byType(TaskReorderCorridor);
        final corridorCenter = tester.getCenter(corridorFinder);
        final corridorTopLeft = tester.getTopLeft(corridorFinder);

        // Start drag of task2 (index 1) to top (index 0)
        container.read(taskDragProvider.notifier).startDrag(task2.id);
        await tester.pump();

        final gesture = await tester.startGesture(corridorCenter);
        addTearDown(gesture.removePointer);

        // Move above container within corridor (Y < top, X centered)
        await gesture.moveTo(
          Offset(corridorCenter.dx, corridorTopLeft.dy - 50),
        );
        await tester.pump();

        expect(container.read(taskDragProvider).hasValidTarget, isTrue);

        // Move horizontally outside corridor (left beyond padding of 16px)
        await gesture.moveTo(
          Offset(corridorTopLeft.dx - 40, corridorTopLeft.dy - 50),
        );
        await tester.pump();

        expect(container.read(taskDragProvider).hasValidTarget, isFalse);

        // Move back inside corridor above container
        await gesture.moveTo(
          Offset(corridorCenter.dx, corridorTopLeft.dy - 50),
        );
        await tester.pump();

        expect(container.read(taskDragProvider).hasValidTarget, isTrue);

        // Release pointer above container
        await gesture.up();
        await tester.pump();

        expect(droppedTask?.id, equals('t2'));
        expect(droppedIndex, equals(0));
      },
    );

    testWidgets(
      'TaskEmptySpaceDropZone accepts drops and routes to bottom slot',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final controller = ScrollController();
        addTearDown(controller.dispose);

        Task? droppedTask;
        int? droppedIndex;

        await tester.pumpWidget(
          buildTestHarness(
            scrollController: controller,
            onDrop: (task, index) {
              droppedTask = task;
              droppedIndex = index;
            },
            container: container,
          ),
        );

        final dragTargetFinder = find.byType(DragTarget<Task>);
        expect(dragTargetFinder, findsOneWidget);

        final dragTarget = tester.widget<DragTarget<Task>>(dragTargetFinder);
        final details = DragTargetDetails<Task>(
          data: task1,
          offset: Offset.zero,
        );

        final willAccept = dragTarget.onWillAcceptWithDetails?.call(details);
        expect(willAccept, isTrue);

        dragTarget.onAcceptWithDetails?.call(details);
        expect(droppedTask?.id, equals('t1'));
        expect(droppedIndex, equals(nodes.length));
      },
    );
  });
}
