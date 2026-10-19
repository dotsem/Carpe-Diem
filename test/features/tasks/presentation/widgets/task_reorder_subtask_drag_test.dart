import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskReorder Subtask Lower-Half Drag & Stability Tests', () {
    late TestTaskRepositories repos;
    final now = DateTime.now();

    final parent = Task(
      id: 'p1',
      title: 'Parent Task',
      sortOrder: 'a0',
      createdAt: now,
    );
    final subtask1 = Task(
      id: 's1',
      parentId: 'p1',
      title: 'Subtask 1',
      sortOrder: 'a0',
      createdAt: now,
    );
    final subtask2 = Task(
      id: 's2',
      parentId: 'p1',
      title: 'Subtask 2',
      sortOrder: 'a1',
      createdAt: now,
    );
    final nextRoot = Task(
      id: 'r2',
      title: 'Next Root Task',
      sortOrder: 'a1',
      createdAt: now,
    );

    final nodes = [
      TaskNode(parent, 0),
      TaskNode(subtask1, 1, isBundledUnderParent: true),
      TaskNode(subtask2, 1, isBundledUnderParent: true),
      TaskNode(nextRoot, 0),
    ];

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    testWidgets(
      'pointerOffset accurately maintains bottom slot when drag offset is in lower half',
      (tester) async {
        late ProviderContainer container;

        await tester.pumpWidget(
          ProviderScope(
            overrides: repos.providerOverrides,
            child: Consumer(
              builder: (context, ref, child) {
                container = ProviderScope.containerOf(context);
                return MaterialApp(
                  home: Scaffold(
                    body: TaskReorderScope(
                      nodes: nodes,
                      onDrop: (_, _) {},
                      child: Builder(
                        builder: (context) {
                          final scope = TaskReorderScope.of(context);
                          final items = [
                            const SizedBox(
                              key: ValueKey('c0'),
                              height: 50,
                              child: Text('Parent'),
                            ),
                            const SizedBox(
                              key: ValueKey('c1'),
                              height: 50,
                              child: Text('Subtask 1'),
                            ),
                            const SizedBox(
                              key: ValueKey('c2'),
                              height: 50,
                              child: Text('Subtask 2'),
                            ),
                            const SizedBox(
                              key: ValueKey('c3'),
                              height: 50,
                              child: Text('Next Root'),
                            ),
                          ];
                          return ValueListenableBuilder<TaskReorderActiveDrop?>(
                            valueListenable: scope!.activeDropNotifier,
                            builder: (context, activeDrop, _) {
                              final slotInfo = TaskReorderListSlot.from(
                                itemCount: items.length,
                                activeDrop: activeDrop,
                              );
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(slotInfo.totalCount, (
                                  i,
                                ) {
                                  if (slotInfo.isPlaceholder(i)) {
                                    return TaskReorderPlaceholderItem(
                                      slotIndex: slotInfo.placeholderIndex!,
                                      task: slotInfo.task!,
                                    );
                                  }
                                  final actualIndex = slotInfo.toOriginalIndex(
                                    i,
                                  );
                                  return TaskReorderItem(
                                    index: actualIndex,
                                    child: items[actualIndex],
                                  );
                                }),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final s2TargetFinder = find.ancestor(
          of: find.byKey(const ValueKey('c2')),
          matching: find.byType(DragTarget<Task>),
        );
        final s2Target = tester.widget<DragTarget<Task>>(s2TargetFinder);

        // Subtask 2 is at index 2 (from y = 100 to y = 150)
        // Simulate dragging subtask1 initiated from its lower half:
        // Pointer is at y = 145 (inside lower half of s2)
        // Grab offset was 40px, so details.offset is at y = 145 - 40 = 105 (upper half of s2!)
        container
            .read(taskDragProvider.notifier)
            .updatePointerOffset(const Offset(50, 145));

        final detailsLowerHalf = DragTargetDetails<Task>(
          data: subtask1,
          offset: const Offset(50, 105),
        );

        s2Target.onMove?.call(detailsLowerHalf);
        await tester.pump();

        // With pointerOffset at 145 (lower half of s2), raw index resolves to 3 (index + 1)
        final scope = TaskReorderScope.of(
          tester.element(find.byKey(const ValueKey('c2'))),
        );
        expect(scope?.activeDropNotifier.value?.slot.index, 3);
        expect(find.byType(TaskCardPlaceholder), findsOneWidget);

        // Move pointer inside the newly opened placeholder at index 3
        container
            .read(taskDragProvider.notifier)
            .updatePointerOffset(const Offset(50, 155));

        final placeholderFinder = find.descendant(
          of: find.byType(TaskReorderPlaceholderItem),
          matching: find.byType(DragTarget<Task>),
        );
        expect(placeholderFinder, findsOneWidget);
        final placeholderTarget = tester.widget<DragTarget<Task>>(
          placeholderFinder,
        );

        final detailsInPlaceholder = DragTargetDetails<Task>(
          data: subtask1,
          offset: const Offset(50, 155),
        );

        placeholderTarget.onMove?.call(detailsInPlaceholder);
        await tester.pump();

        // Crucial: Must stay at index 3 and NOT collapse to index 2
        expect(scope?.activeDropNotifier.value?.slot.index, 3);
        expect(find.byType(TaskCardPlaceholder), findsOneWidget);
      },
    );

    testWidgets(
      'placeholder zone guard locks to index + 1 when localY is in bottom placeholder',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: repos.providerOverrides,
            child: MaterialApp(
              home: Scaffold(
                body: TaskReorderScope(
                  nodes: nodes,
                  onDrop: (_, _) {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TaskReorderItem(
                        index: 2,
                        child: const SizedBox(
                          key: ValueKey('c2_guard'),
                          height: 50,
                          child: Text('Subtask 2'),
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

        final s2TargetFinder = find.ancestor(
          of: find.byKey(const ValueKey('c2_guard')),
          matching: find.byType(DragTarget<Task>),
        );
        final s2Target = tester.widget<DragTarget<Task>>(s2TargetFinder);

        // Simulate pointer position past box height without pointerOffset override
        final detailsPastBottom = DragTargetDetails<Task>(
          data: subtask1,
          offset: const Offset(50, 60), // box height is 50
        );

        s2Target.onMove?.call(detailsPastBottom);
        await tester.pump();

        final scope = TaskReorderScope.of(
          tester.element(find.byKey(const ValueKey('c2_guard'))),
        );
        expect(scope?.activeDropNotifier.value?.slot.index, 3);
      },
    );
  });
}
