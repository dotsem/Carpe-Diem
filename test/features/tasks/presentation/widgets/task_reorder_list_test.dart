import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_empty_space_drop_zone.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskReorderScope and TaskReorderItem', () {
    late TestTaskRepositories repos;
    final now = DateTime.now();
    final urgentTask = Task(
      id: 'u1',
      title: 'Urgent Task',
      isUrgent: true,
      createdAt: now,
    );
    final normalTask1 = Task(
      id: 'n1',
      title: 'Normal Task 1',
      isUrgent: false,
      createdAt: now,
    );
    final normalTask2 = Task(
      id: 'n2',
      title: 'Normal Task 2',
      isUrgent: false,
      createdAt: now,
    );

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    Widget buildTestList({
      required List<TaskHierarchyNode> nodes,
      void Function(Task, int)? onDrop,
      bool includeEmptySpace = false,
    }) {
      return ProviderScope(
        overrides: repos.providerOverrides,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TaskReorderScope(
                nodes: nodes,
                onDrop: onDrop ?? (_, _) {},
                child: Column(
                  children: [
                    ...List.generate(
                      nodes.length,
                      (i) => TaskReorderItem(
                        index: i,
                        child: Container(
                          key: ValueKey('item-$i'),
                          height: 50,
                          color: Colors.grey[200],
                          child: Text(nodes[i].task?.title ?? 'Item $i'),
                        ),
                      ),
                    ),
                    if (includeEmptySpace)
                      SizedBox(
                        height: 100,
                        child: TaskEmptySpaceDropZone(onDrop: onDrop),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'pointer over top half resolves to index and bottom half resolves to index + 1',
      (tester) async {
        final nodes = [TaskNode(normalTask1, 0), TaskNode(normalTask2, 0)];

        await tester.pumpWidget(buildTestList(nodes: nodes));

        final BuildContext context = tester.element(
          find.byKey(const ValueKey('item-0')),
        );
        final scope = TaskReorderScope.of(context);
        expect(scope, isNotNull);

        // Hover top half (rawIndex: 0) of item with dragged normalTask2
        scope!.onHoverSlot(normalTask2, 0);
        await tester.pump();

        expect(find.byType(TaskCardPlaceholder), findsOneWidget);

        // Hover bottom half (rawIndex: 1) -> same position as current index (1) -> unchanged
        scope.onHoverSlot(normalTask2, 1);
        await tester.pump();

        expect(find.byType(TaskCardPlaceholder), findsNothing);

        // Hover top half of item 0 (index: 0) with normalTask2 -> valid and changed!
        scope.onHoverSlot(normalTask2, 0);
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsOneWidget);

        // Leaving slot clears placeholder
        scope.onLeaveSlot();
        await tester.pump();
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsNothing);
      },
    );

    testWidgets(
      'boundary clamping snaps non-urgent task outside urgent section',
      (tester) async {
        final nodes = [TaskNode(urgentTask, 0), TaskNode(normalTask1, 0)];

        await tester.pumpWidget(buildTestList(nodes: nodes));

        final BuildContext context = tester.element(
          find.byKey(const ValueKey('item-0')),
        );
        final scope = TaskReorderScope.of(context);
        expect(scope, isNotNull);

        // Non-urgent task trying to hover raw index 0 (above urgent task)
        final slot = scope!.resolveSlot(normalTask2, 0);
        // Snapped to urgent section end index (1)
        expect(slot.index, 1);
        expect(slot.isValid, isTrue);

        // Urgent task trying to hover index 2 (below non-urgent section)
        final urgentSlot = scope.resolveSlot(urgentTask, 2);
        // Snapped to urgent section end index (1)
        expect(urgentSlot.index, 1);
      },
    );

    testWidgets('dropping executes onDrop callback with resolved slot index', (
      tester,
    ) async {
      final nodes = [TaskNode(normalTask1, 0), TaskNode(normalTask2, 0)];

      int? droppedIndex;
      Task? droppedTask;

      await tester.pumpWidget(
        buildTestList(
          nodes: nodes,
          onDrop: (task, index) {
            droppedTask = task;
            droppedIndex = index;
          },
        ),
      );

      final BuildContext context = tester.element(
        find.byKey(const ValueKey('item-0')),
      );
      final scope = TaskReorderScope.of(context);
      expect(scope, isNotNull);

      // Drop normalTask2 at top (index 0)
      scope!.drop(normalTask2, 0);
      await tester.pump();

      expect(droppedTask?.id, 'n2');
      expect(droppedIndex, 0);
    });

    testWidgets('empty space drop zone routes drop to bottom index', (
      tester,
    ) async {
      final nodes = [TaskNode(normalTask1, 0), TaskNode(normalTask2, 0)];

      int? droppedIndex;
      Task? droppedTask;

      await tester.pumpWidget(
        buildTestList(
          nodes: nodes,
          includeEmptySpace: true,
          onDrop: (task, index) {
            droppedTask = task;
            droppedIndex = index;
          },
        ),
      );

      final dragTargetFinder = find.descendant(
        of: find.byType(TaskEmptySpaceDropZone),
        matching: find.byType(DragTarget<Task>),
      );
      expect(dragTargetFinder, findsOneWidget);

      final dragTarget = tester.widget<DragTarget<Task>>(dragTargetFinder);
      final details = DragTargetDetails<Task>(
        data: normalTask1,
        offset: Offset.zero,
      );

      final willAccept = dragTarget.onWillAcceptWithDetails?.call(details);
      expect(willAccept, isTrue);

      dragTarget.onAcceptWithDetails?.call(details);
      await tester.pump();

      expect(droppedTask?.id, 'n1');
      expect(droppedIndex, 2);
    });
  });
}
