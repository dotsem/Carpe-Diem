import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/task_form_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('TaskFormShortcuts', () {
    late TestTaskRepositories repos;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    Widget buildTestWidget({
      Task? initialTask,
      DateTime? initialDate,
      String? initialProjectId,
      String? initialParentId,
    }) {
      return ProviderScope(
        overrides: repos.providerOverrides,
        child: MaterialApp(
          home: Scaffold(
            body: TaskFormPanel(
              initialTask: initialTask,
              initialDate: initialDate,
              initialProjectId: initialProjectId,
              initialParentId: initialParentId,
            ),
          ),
        ),
      );
    }

    testWidgets('Ctrl+B opens and closes blockers menu', (tester) async {
      final project = Project(
        id: 'p1',
        name: 'Project 1',
        color: Colors.blue,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final blockerTask = createTestTask(
        id: 'task_b',
        title: 'Blocker Task',
        projectId: 'p1',
      );

      when(
        () => repos.mockProjectRepo.getAll(),
      ).thenAnswer((_) async => [project]);
      when(
        () => repos.mockTaskRepo.getByProject('p1'),
      ).thenAnswer((_) async => [blockerTask]);

      await tester.pumpWidget(buildTestWidget(initialProjectId: 'p1'));
      await tester.pumpAndSettle();

      expect(find.text('Search tasks...'), findsNothing);

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(BlockersKeys.keyboardKey);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.text('Search tasks...'), findsOneWidget);

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(BlockersKeys.keyboardKey);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.text('Search tasks...'), findsNothing);
    });

    testWidgets('Ctrl+L opens and closes labels menu', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Label'), findsNothing);

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LabelsKeys.keyboardKey);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.text('New Label'), findsOneWidget);

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LabelsKeys.keyboardKey);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.text('New Label'), findsNothing);
    });

    testWidgets('Ctrl+T opens and closes tags menu', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Tag'), findsNothing);

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(TagsKeys.keyboardKey);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.text('New Tag'), findsOneWidget);

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(TagsKeys.keyboardKey);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.text('New Tag'), findsNothing);
    });

    testWidgets('Ctrl+N opens subtask panel when editing task', (tester) async {
      final parentTask = createTestTask(
        id: 'parent_1',
        title: 'Existing Parent Task',
        projectId: 'proj_1',
        scheduledDate: DateTime(2026, 5, 20),
      );

      when(
        () => repos.mockTaskRepo.getById('parent_1'),
      ).thenAnswer((_) async => parentTask);

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return TaskFormPanel(initialTask: parentTask);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(SubtaskKeys.keyboardKey);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      final activePanel = capturedRef.read(rightSidebarProvider).activePanel;
      expect(
        activePanel,
        equals(
          AddTaskPanel(
            initialDate: DateTime(2026, 5, 20),
            initialProjectId: 'proj_1',
            initialParentId: 'parent_1',
          ),
        ),
      );
    });
  });
}
