import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskDropZoneScope and TaskDropZoneWrapper', () {
    final now = DateTime.now();
    final urgentTask = Task(
      id: 'u1',
      title: 'Urgent Task',
      isUrgent: true,
      createdAt: now,
    );
    final normalTask = Task(
      id: 'n1',
      title: 'Normal Task',
      isUrgent: false,
      createdAt: now,
    );

    testWidgets(
      'clamped drop index redirects indicator to urgentSectionEndIndex for non-urgent task',
      (tester) async {
        int? droppedIndex;
        Task? droppedTask;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskDropZoneScope(
                urgentSectionEndIndex: 2,
                itemCount: 4,
                child: Column(
                  children: [
                    TaskDropZoneWrapper(
                      index: 0,
                      onDrop: (task, index) {
                        droppedTask = task;
                        droppedIndex = index;
                      },
                      child: const SizedBox(
                        key: ValueKey('item-0'),
                        height: 50,
                        child: Text('Urgent 1'),
                      ),
                    ),
                    TaskDropZoneWrapper(
                      index: 1,
                      onDrop: (task, index) {
                        droppedTask = task;
                        droppedIndex = index;
                      },
                      child: const SizedBox(
                        key: ValueKey('item-1'),
                        height: 50,
                        child: Text('Urgent 2'),
                      ),
                    ),
                    TaskDropZoneWrapper(
                      index: 2,
                      onDrop: (task, index) {
                        droppedTask = task;
                        droppedIndex = index;
                      },
                      child: const SizedBox(
                        key: ValueKey('item-2'),
                        height: 50,
                        child: Text('Normal 1'),
                      ),
                    ),
                    TaskDropZoneWrapper(
                      index: 3,
                      onDrop: (task, index) {
                        droppedTask = task;
                        droppedIndex = index;
                      },
                      child: const SizedBox(
                        key: ValueKey('item-3'),
                        height: 50,
                        child: Text('Normal 2'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Scope resolution checks directly
        final BuildContext context = tester.element(
          find.byKey(const ValueKey('item-0')),
        );
        final scope = TaskDropZoneScope.of(context);
        expect(scope, isNotNull);

        // Non-urgent task hovering at index 0 should be clamped to 2
        expect(scope!.resolveEffectiveIndex(normalTask, 0), 2);
        expect(scope.resolveEffectiveIndex(normalTask, 1), 2);
        expect(scope.resolveEffectiveIndex(normalTask, 2), 2);
        expect(scope.resolveEffectiveIndex(normalTask, 3), 3);

        // Urgent task hovering at index 3 should be clamped to 2
        expect(scope.resolveEffectiveIndex(urgentTask, 0), 0);
        expect(scope.resolveEffectiveIndex(urgentTask, 1), 1);
        expect(scope.resolveEffectiveIndex(urgentTask, 2), 2);
        expect(scope.resolveEffectiveIndex(urgentTask, 3), 2);

        // Test dropping on DragTarget at index 0
        final dragTargets = find.byType(DragTarget<Task>);
        final topDragTarget0 = tester.widget<DragTarget<Task>>(
          dragTargets.first,
        );

        // Simulate drop of normalTask at top of item 0
        topDragTarget0.onAcceptWithDetails?.call(
          DragTargetDetails<Task>(data: normalTask, offset: Offset.zero),
        );

        expect(droppedTask?.id, 'n1');
        expect(droppedIndex, 2);
      },
    );
  });
}
