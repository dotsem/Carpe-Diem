import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_panel_body.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/undo_redo_panel.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepo extends Mock implements ITaskRepository {}

class TestCommand extends Command {
  final String desc;
  TestCommand(this.desc);

  @override
  Future<void> execute() async {}

  @override
  Future<void> undo() async {}

  @override
  String get description => desc;
}

void main() {
  Widget buildTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, child) {
          final sidebarState = ref.watch(rightSidebarProvider);
          return MaterialApp(
            home: Scaffold(
              bottomNavigationBar: const UndoRedoPanel(),
              body: sidebarState.isOpen
                  ? RightSidebarPanelBody(panel: sidebarState.activePanel!)
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  group('UndoRedoPanel Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets(
      'should render with height 0 when empty and 56 when populated',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(container));

        // verify initial height is 0
        var animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(animatedContainer.constraints?.maxHeight, equals(0.0));

        // execute a command to trigger panel visibility
        final cmd = TestCommand('First Action');
        await container.read(undoRedoProvider.notifier).execute(cmd);
        await tester.pumpAndSettle();

        animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(animatedContainer.constraints?.maxHeight, equals(56.0));
      },
    );

    testWidgets('Undo and Redo button states and click handlers work', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(container));

      final cmd = TestCommand('Action 1');
      await container.read(undoRedoProvider.notifier).execute(cmd);
      await tester.pumpAndSettle();

      // Undo should be enabled, Redo disabled
      final undoFinder = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Undo',
      );
      final redoFinder = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Redo',
      );

      IconButton undoButton = tester.widget<IconButton>(undoFinder);
      IconButton redoButton = tester.widget<IconButton>(redoFinder);

      expect(undoButton.onPressed, isNotNull);
      expect(redoButton.onPressed, isNull);

      // Tap Undo
      await tester.tap(undoFinder);
      await tester.pumpAndSettle();

      // States should swap: Undo disabled, Redo enabled
      undoButton = tester.widget<IconButton>(undoFinder);
      redoButton = tester.widget<IconButton>(redoFinder);

      expect(undoButton.onPressed, isNull);
      expect(redoButton.onPressed, isNotNull);

      // Tap Redo
      await tester.tap(redoFinder);
      await tester.pumpAndSettle();

      undoButton = tester.widget<IconButton>(undoFinder);
      redoButton = tester.widget<IconButton>(redoFinder);

      expect(undoButton.onPressed, isNotNull);
      expect(redoButton.onPressed, isNull);
    });

    testWidgets('History button should open ActionHistoryPanel', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(container));

      final cmd = TestCommand('Historical Action');
      await container.read(undoRedoProvider.notifier).execute(cmd);
      await tester.pumpAndSettle();

      final historyFinder = find.byTooltip('Action History');
      await tester.tap(historyFinder);
      await tester.pumpAndSettle();

      // Verify panel is visible
      expect(find.byType(ActionHistoryPanelWidget), findsOneWidget);
      expect(find.text('Historical Action'), findsOneWidget);
      expect(find.text('Applied'), findsOneWidget);

      // Close panel
      container.read(rightSidebarProvider.notifier).close();
      await tester.pumpAndSettle();

      expect(find.byType(ActionHistoryPanelWidget), findsNothing);
    });

    testWidgets('ActionHistoryDialog jumpTo interaction works', (tester) async {
      await tester.pumpWidget(buildTestWidget(container));

      final cmd1 = TestCommand('Action 1');
      final cmd2 = TestCommand('Action 2');

      await container.read(undoRedoProvider.notifier).execute(cmd1);
      await container.read(undoRedoProvider.notifier).execute(cmd2);
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.byTooltip('Action History'));
      await tester.pumpAndSettle();

      // Tap the first action to trigger jumpTo (undos action 2)
      await tester.tap(find.text('Action 1'));
      await tester.pumpAndSettle();

      // Action 1 should be Applied, Action 2 should show Undone
      expect(find.text('Applied'), findsOneWidget); // Action 1 is applied
      expect(find.text('Undone'), findsOneWidget); // Action 2 is undone
    });

    testWidgets(
      'ActionHistoryPanelWidget displays action specific icons and colors',
      (tester) async {
        final mockRepo = MockTaskRepo();
        final task = Task(
          id: '1',
          title: 'New Task',
          createdAt: DateTime(2026, 1, 1),
        );
        when(() => mockRepo.repositoryName).thenReturn('Task');
        when(() => mockRepo.insert(task)).thenAnswer((_) async {});
        when(() => mockRepo.delete(task.id)).thenAnswer((_) async {});
        final createCmd = CreateCommand<Task>(
          repo: mockRepo,
          item: task,
          id: task.id,
          displayName: task.title,
        );

        await container.read(undoRedoProvider.notifier).execute(createCmd);
        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Action History'));
        await tester.pumpAndSettle();

        final iconFinder = find.byIcon(Icons.add_task);
        expect(iconFinder, findsOneWidget);

        final iconWidget = tester.widget<Icon>(iconFinder);
        expect(iconWidget.color, equals(AppColors.success));

        final appliedFinder = find.text('Applied');
        expect(appliedFinder, findsOneWidget);
        final appliedText = tester.widget<Text>(appliedFinder);
        expect(appliedText.style?.color, equals(AppColors.success));
      },
    );

    testWidgets(
      'ActionHistoryPanelWidget orders newest first and shows current state divider when undone',
      (tester) async {
        final cmd1 = TestCommand('Older Action');
        final cmd2 = TestCommand('Newer Action');

        await container.read(undoRedoProvider.notifier).execute(cmd1);
        await container.read(undoRedoProvider.notifier).execute(cmd2);
        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Action History'));
        await tester.pumpAndSettle();

        // Verify newest is above older
        final olderPos = tester.getTopLeft(find.text('Older Action'));
        final newerPos = tester.getTopLeft(find.text('Newer Action'));
        expect(newerPos.dy, lessThan(olderPos.dy));

        // When nothing is undone, divider is not shown
        expect(find.text('Current state'), findsNothing);

        // Undo newer action
        await container.read(undoRedoProvider.notifier).undo();
        await tester.pumpAndSettle();

        // Now divider is visible between Newer Action (undone) and Older Action (current)
        expect(find.text('Current state'), findsOneWidget);
        final dividerPos = tester.getTopLeft(find.text('Current state'));
        final newerPosAfterUndo = tester.getTopLeft(find.text('Newer Action'));
        final olderPosAfterUndo = tester.getTopLeft(find.text('Older Action'));

        expect(newerPosAfterUndo.dy, lessThan(dividerPos.dy));
        expect(dividerPos.dy, lessThan(olderPosAfterUndo.dy));
      },
    );
  });
}
