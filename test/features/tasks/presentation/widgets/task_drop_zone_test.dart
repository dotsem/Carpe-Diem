import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskDropZoneScope and TaskDropZoneWrapper', () {
    late TestTaskRepositories repos;
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

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    Widget buildTestList({
      int urgentSectionEndIndex = 0,
      int itemCount = 4,
      bool Function(Task, int)? isPositionUnchanged,
      void Function(Task, int)? onDrop,
    }) {
      return ProviderScope(
        overrides: repos.providerOverrides,
        child: MaterialApp(
          home: Scaffold(
            body: TaskDropZoneScope(
              urgentSectionEndIndex: urgentSectionEndIndex,
              itemCount: itemCount,
              isPositionUnchanged: isPositionUnchanged,
              child: Column(
                children: List.generate(
                  itemCount,
                  (i) => TaskDropZoneWrapper(
                    index: i,
                    onDrop: onDrop ?? (_, _) {},
                    child: SizedBox(
                      key: ValueKey('item-$i'),
                      height: 50,
                      child: Text('Item $i'),
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
      'clamped drop index redirects indicator to urgentSectionEndIndex for non-urgent task',
      (tester) async {
        int? droppedIndex;
        Task? droppedTask;

        await tester.pumpWidget(
          buildTestList(
            urgentSectionEndIndex: 2,
            itemCount: 4,
            onDrop: (task, index) {
              droppedTask = task;
              droppedIndex = index;
            },
          ),
        );

        final BuildContext context = tester.element(
          find.byKey(const ValueKey('item-0')),
        );
        final scope = TaskDropZoneScope.of(context);
        expect(scope, isNotNull);

        expect(scope!.resolveEffectiveIndex(normalTask, 0), 2);
        expect(scope.resolveEffectiveIndex(normalTask, 1), 2);
        expect(scope.resolveEffectiveIndex(normalTask, 2), 2);
        expect(scope.resolveEffectiveIndex(normalTask, 3), 3);

        expect(scope.resolveEffectiveIndex(urgentTask, 0), 0);
        expect(scope.resolveEffectiveIndex(urgentTask, 1), 1);
        expect(scope.resolveEffectiveIndex(urgentTask, 2), 2);
        expect(scope.resolveEffectiveIndex(urgentTask, 3), 2);

        final dragTargets = find.byType(DragTarget<Task>);
        final topDragTarget0 = tester.widget<DragTarget<Task>>(
          dragTargets.first,
        );

        topDragTarget0.onAcceptWithDetails?.call(
          DragTargetDetails<Task>(data: normalTask, offset: Offset.zero),
        );

        expect(droppedTask?.id, 'n1');
        expect(droppedIndex, 2);
      },
    );

    testWidgets(
      'shows semi-transparent task card placeholder when active drop is set',
      (tester) async {
        await tester.pumpWidget(buildTestList(itemCount: 2));

        final BuildContext context = tester.element(
          find.byKey(const ValueKey('item-0')),
        );
        final scope = TaskDropZoneScope.of(context);
        expect(scope, isNotNull);
        expect(find.byType(TaskCardPlaceholder), findsNothing);

        scope!.activeDropNotifier.value = TaskDropState(
          index: 0,
          task: normalTask,
        );
        await tester.pump();

        expect(find.byType(TaskCardPlaceholder), findsOneWidget);
        expect(find.text('Normal Task'), findsOneWidget);

        final opacityWidget = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(TaskCardPlaceholder),
            matching: find.byType(Opacity),
          ),
        );
        expect(opacityWidget.opacity, 0.5);

        scope.activeDropNotifier.value = TaskDropState(
          index: 2,
          task: normalTask,
        );
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsOneWidget);

        scope.activeDropNotifier.value = null;
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsNothing);
      },
    );

    testWidgets('dropping on placeholder calls onDrop with correct index', (
      tester,
    ) async {
      int? droppedIndex;
      Task? droppedTask;

      await tester.pumpWidget(
        buildTestList(
          itemCount: 2,
          onDrop: (task, index) {
            droppedTask = task;
            droppedIndex = index;
          },
        ),
      );

      final BuildContext context = tester.element(
        find.byKey(const ValueKey('item-0')),
      );
      final scope = TaskDropZoneScope.of(context);
      expect(scope, isNotNull);

      scope!.activeDropNotifier.value = TaskDropState(
        index: 0,
        task: normalTask,
      );
      await tester.pump();

      final placeholderDragTargetFinder = find.descendant(
        of: find.byType(TaskDropZoneWrapper).first,
        matching: find.byType(DragTarget<Task>),
      );
      final placeholderDragTarget = tester.widget<DragTarget<Task>>(
        placeholderDragTargetFinder.first,
      );

      placeholderDragTarget.onAcceptWithDetails?.call(
        DragTargetDetails<Task>(data: normalTask, offset: Offset.zero),
      );

      expect(droppedTask?.id, 'n1');
      expect(droppedIndex, 0);
      expect(scope.activeDropNotifier.value, isNull);
    });

    testWidgets(
      'suppresses placeholder when task is hovered above its current position',
      (tester) async {
        // normalTask is at index 1
        final taskIds = ['u1', 'n1', 'other'];

        await tester.pumpWidget(
          buildTestList(
            itemCount: 3,
            isPositionUnchanged: (task, targetIndex) {
              final idx = taskIds.indexOf(task.id);
              return TaskReorderUtils.isPositionUnchanged(
                currentIndex: idx,
                targetIndex: targetIndex,
              );
            },
          ),
        );

        final BuildContext context = tester.element(
          find.byKey(const ValueKey('item-0')),
        );
        final scope = TaskDropZoneScope.of(context);
        expect(scope, isNotNull);

        // Hovering at index 1 (above itself): suppressed!
        scope!.activeDropNotifier.value = TaskDropState(
          index: 1,
          task: normalTask,
        );
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsNothing);

        // Hovering at index 2 (below itself): suppressed!
        scope.activeDropNotifier.value = TaskDropState(
          index: 2,
          task: normalTask,
        );
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsNothing);

        // Hovering at index 0 (above item 0): shown!
        scope.activeDropNotifier.value = TaskDropState(
          index: 0,
          task: normalTask,
        );
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsOneWidget);

        // Hovering at index 3 (after item 2): shown!
        scope.activeDropNotifier.value = TaskDropState(
          index: 3,
          task: normalTask,
        );
        await tester.pump();
        expect(find.byType(TaskCardPlaceholder), findsOneWidget);
      },
    );
  });
}
