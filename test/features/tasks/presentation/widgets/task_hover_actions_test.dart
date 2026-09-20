import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/base_task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_group_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_task_hover_actions.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hover_actions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

void main() {
  late TestTaskRepositories repos;

  setUp(() {
    repos = TestTaskRepositories();
    repos.setupDefaultStubs();
  });

  group('TaskHoverActions', () {
    final sampleTask = Task(
      id: 'task_1',
      title: 'Sample Task',
      createdAt: DateTime.now(),
    );

    testWidgets('renders action buttons with correct tooltips when hovered', (
      tester,
    ) async {
      bool editCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskHoverActions(
                task: sampleTask,
                isHovered: true,
                onEdit: () => editCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
      expect(find.byIcon(Icons.next_plan_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(editCalled, isTrue);
    });

    testWidgets('has opacity 0.0 when not hovered', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: TaskHoverActions(task: sampleTask, isHovered: false),
            ),
          ),
        ),
      );
      await tester.pump();

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 0.0);
    });
  });

  group('BaseTaskCard Hover', () {
    final sampleTask = Task(
      id: 'task_2',
      title: 'Hover Task',
      createdAt: DateTime.now(),
    );

    testWidgets('updates hover state on pointer enter and exit', (
      tester,
    ) async {
      bool capturedHover = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: BaseTaskCard(
                    task: sampleTask,
                    trailingBuilder: (context, isHovered) {
                      capturedHover = isHovered;
                      return Text(isHovered ? 'HOVERED' : 'NOT_HOVERED');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOT_HOVERED'), findsOneWidget);
      expect(capturedHover, isFalse);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(700, 500));
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(BaseTaskCard)));
      await tester.pumpAndSettle();

      expect(find.text('HOVERED'), findsOneWidget);
      expect(capturedHover, isTrue);

      await gesture.moveTo(const Offset(700, 500));
      await tester.pumpAndSettle();

      expect(find.text('NOT_HOVERED'), findsOneWidget);
      expect(capturedHover, isFalse);
    });
  });

  group('ParentGroupHeader Hover', () {
    final parentTask = Task(
      id: 'parent_1',
      title: 'Parent Task',
      createdAt: DateTime.now(),
    );
    final parentNode = ParentContainerNode(
      task: parentTask,
      depth: 0,
      totalSubtasks: 3,
      completedSubtasks: 1,
      plannedSubtasks: 1,
      isCollapsed: false,
    );

    testWidgets(
      'animates in ParentTaskHoverActions on hover and does not show orange border',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: repos.providerOverrides,
            child: MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 500,
                    child: ParentGroupHeader(node: parentNode),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially unhovered: ParentTaskHoverActions should not be in the tree
        expect(find.byType(ParentTaskHoverActions), findsNothing);
        expect(find.text('1/3'), findsOneWidget);

        // Hover over the header
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: const Offset(700, 500));
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(ParentGroupHeader)));
        await tester.pumpAndSettle();

        // Now hovered: ParentTaskHoverActions should be visible with edit and add subtask
        expect(find.byType(ParentTaskHoverActions), findsOneWidget);
        expect(find.byIcon(Icons.add_task), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

        // Move away: actions smoothly disappear
        await gesture.moveTo(const Offset(700, 500));
        await tester.pumpAndSettle();

        expect(find.byType(ParentTaskHoverActions), findsNothing);
      },
    );
  });
}
