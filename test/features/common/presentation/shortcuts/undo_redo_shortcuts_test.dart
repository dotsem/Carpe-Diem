import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mock_repositories.dart';

class CustomMockUndoRedoNotifier extends UndoRedoNotifier {
  bool undoCalled = false;
  bool redoCalled = false;

  @override
  UndoRedoState build() {
    return const UndoRedoState(canUndo: true, canRedo: true);
  }

  @override
  Future<void> undo() async {
    undoCalled = true;
  }

  @override
  Future<void> redo() async {
    redoCalled = true;
  }
}

void main() {
  group('GlobalShortcuts Undo/Redo Tests', () {
    late CustomMockUndoRedoNotifier mockUndoRedoNotifier;
    late MockSettingsRepository mockSettingsRepo;
    late ProviderContainer container;

    setUp(() {
      mockUndoRedoNotifier = CustomMockUndoRedoNotifier();
      mockSettingsRepo = MockSettingsRepository();
      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          undoRedoProvider.overrideWith(() => mockUndoRedoNotifier),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildTestWidget(Widget child) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: GlobalShortcuts(child: child)),
        ),
      );
    }

    testWidgets('Ctrl+Z should trigger undo and Ctrl+Y should trigger redo when not typing', (tester) async {
      final focusNode = FocusNode();
      await tester.pumpWidget(
        buildTestWidget(Focus(focusNode: focusNode, autofocus: true, child: const SizedBox(width: 10, height: 10))),
      );

      focusNode.requestFocus();
      await tester.pump();

      // Trigger Ctrl+Z
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(mockUndoRedoNotifier.undoCalled, isTrue);

      // Trigger Ctrl+Y
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(mockUndoRedoNotifier.redoCalled, isTrue);
    });

    testWidgets('Ctrl+Z and Ctrl+Y should be ignored when typing in TextField', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestWidget(TextField(controller: controller, autofocus: true)));

      // Ensure TextField has focus
      await tester.showKeyboard(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(FocusManager.instance.primaryFocus, isNotNull);

      // Trigger Ctrl+Z
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      // Undo should NOT be called globally because we are inside a text input field
      expect(mockUndoRedoNotifier.undoCalled, isFalse);

      // Trigger Ctrl+Y
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      // Redo should NOT be called globally
      expect(mockUndoRedoNotifier.redoCalled, isFalse);
    });
  });
}
