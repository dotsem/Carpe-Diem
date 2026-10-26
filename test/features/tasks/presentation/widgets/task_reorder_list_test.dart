import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_slot.dart';
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
                child: Builder(
                  builder: (context) {
                    final scope = TaskReorderScope.of(context);
                    return ValueListenableBuilder<TaskReorderActiveDrop?>(
                      valueListenable: scope!.activeDropNotifier,
                      builder: (context, activeDrop, _) {
                        final slotInfo = TaskReorderListSlot.from(
                          itemCount: nodes.length,
                          activeDrop: activeDrop,
                        );
                        return Column(
                          children: [
                            ...List.generate(slotInfo.totalCount, (i) {
                              if (slotInfo.isPlaceholder(i)) {
                                return TaskReorderPlaceholderItem(
                                  slotIndex: slotInfo.placeholderIndex!,
                                  task: slotInfo.task!,
                                );
                              }
                              final itemIndex = slotInfo.toOriginalIndex(i);
                              return TaskReorderItem(
                                index: itemIndex,
                                child: Container(
                                  key: ValueKey('item-$itemIndex'),
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: Text(
                                    nodes[itemIndex].task?.title ??
                                        'Item $itemIndex',
                                  ),
                                ),
                              );
                            }),
                            if (includeEmptySpace)
                              SizedBox(
                                height: 100,
                                child: const TaskEmptySpaceDropZone(),
                              ),
                          ],
                        );
                      },
                    );
                  },
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

        expect(find.byType(TaskReorderPlaceholderItem), findsOneWidget);

        // Hover bottom half (rawIndex: 1) -> same position as current index (1) -> unchanged
        scope.onHoverSlot(normalTask2, 1);
        await tester.pump();

        expect(find.byType(TaskReorderPlaceholderItem), findsNothing);

        // Hover top half of item 0 (index: 0) with normalTask2 -> valid and changed!
        scope.onHoverSlot(normalTask2, 0);
        await tester.pump();
        expect(find.byType(TaskReorderPlaceholderItem), findsOneWidget);

        // Leaving slot clears placeholder
        scope.onLeaveSlot();
        await tester.pump();
        await tester.pump();
        expect(find.byType(TaskReorderPlaceholderItem), findsNothing);
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

    test('empty list with active drop creates placeholder at index 0', () {
      final drop = TaskReorderActiveDrop(
        index: 0,
        task: normalTask1,
        slot: const TaskReorderSlot(
          index: 0,
          isValid: true,
          isUnchanged: false,
        ),
      );
      final slot = TaskReorderListSlot.from(itemCount: 0, activeDrop: drop);
      expect(slot.totalCount, 1);
      expect(slot.placeholderIndex, 0);
      expect(slot.isPlaceholder(0), isTrue);
    });

    test(
      'dragged task leaving source column collapses gap and excludes item',
      () {
        final slot = TaskReorderListSlot.from(
          itemCount: 3,
          activeDrop: null,
          draggedIndex: 1,
        );
        expect(slot.totalCount, 2);
        expect(slot.placeholderIndex, isNull);
        expect(slot.toOriginalIndex(0), 0);
        expect(slot.toOriginalIndex(1), 2);
      },
    );

    test('dragged task hovering in same column maintains placeholder gap', () {
      final drop = TaskReorderActiveDrop(
        index: 0,
        task: normalTask1,
        slot: const TaskReorderSlot(
          index: 0,
          isValid: true,
          isUnchanged: false,
        ),
      );
      final slot = TaskReorderListSlot.from(
        itemCount: 3,
        activeDrop: drop,
        draggedIndex: 2,
      );
      expect(slot.totalCount, 3);
      expect(slot.placeholderIndex, 0);
      expect(slot.toOriginalIndex(1), 0);
      expect(slot.toOriginalIndex(2), 1);
    });
  });
}
