import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/presentation/shell/undo_redo_panel.dart';

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
      child: const MaterialApp(home: Scaffold(bottomNavigationBar: UndoRedoPanel())),
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

    testWidgets('should render with height 0 when empty and 56 when populated', (tester) async {
      await tester.pumpWidget(buildTestWidget(container));

      // verify initial height is 0
      var animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainer.constraints?.maxHeight, equals(0.0));

      // execute a command to trigger panel visibility
      final cmd = TestCommand('First Action');
      await container.read(undoRedoProvider.notifier).execute(cmd);
      await tester.pumpAndSettle();

      animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainer.constraints?.maxHeight, equals(56.0));
    });

    testWidgets('Undo and Redo button states and click handlers work', (tester) async {
      await tester.pumpWidget(buildTestWidget(container));

      final cmd = TestCommand('Action 1');
      await container.read(undoRedoProvider.notifier).execute(cmd);
      await tester.pumpAndSettle();

      // Undo should be enabled, Redo disabled
      final undoFinder = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Undo');
      final redoFinder = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Redo');

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

    testWidgets('History button should open ActionHistoryDialog', (tester) async {
      await tester.pumpWidget(buildTestWidget(container));

      final cmd = TestCommand('Historical Action');
      await container.read(undoRedoProvider.notifier).execute(cmd);
      await tester.pumpAndSettle();

      final historyFinder = find.byTooltip('Action History');
      await tester.tap(historyFinder);
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.byType(ActionHistoryDialog), findsOneWidget);
      expect(find.text('Historical Action'), findsOneWidget);
      expect(find.text('Applied'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(ActionHistoryDialog), findsNothing);
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
  });
}
