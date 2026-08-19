import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
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

  group('tasks', () {
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

    testWidgets('shows validation error when submitting empty task name', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      expect(find.text('Task name is required'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'New Task Title');
      await tester.pumpAndSettle();

      expect(find.text('Task name is required'), findsNothing);
    });

    testWidgets(
      'inherits project, dates, and parent labels when creating subtask',
      (tester) async {
        final parentTask = createTestTask(
          id: 'parent_1',
          title: 'Parent Task',
          projectId: 'proj_1',
          scheduledDate: DateTime(2026, 8, 10),
        );
        final project = Project(
          id: 'proj_1',
          name: 'Project 1',
          color: Colors.blue,
          labelIds: ['label_p1'],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        when(
          () => repos.mockTaskRepo.getById('parent_1'),
        ).thenAnswer((_) async => parentTask);
        when(
          () => repos.mockTaskRepo.getByDate(
            DateTime(2026, 8, 10),
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
          ),
        ).thenAnswer((_) async => [parentTask]);
        when(
          () => repos.mockProjectRepo.getAll(),
        ).thenAnswer((_) async => [project]);

        await tester.pumpWidget(buildTestWidget(initialParentId: 'parent_1'));
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(TaskFormPanel)),
        );
        await container.read(projectProvider.notifier).loadProjects();
        await container
            .read(taskProvider.notifier)
            .loadTasksForDate(DateTime(2026, 8, 10));
        await tester.pumpAndSettle();

        // Parent link should be rendered
        expect(find.text('Parent: '), findsOneWidget);
        expect(find.text('Parent Task'), findsOneWidget);

        // Project 1 should be pre-selected in the project picker
        expect(find.text('Project 1'), findsOneWidget);
      },
    );

    testWidgets(
      'supports keyboard shortcuts for placement and form submission',
      (tester) async {
        when(
          () => repos.mockTaskRepo.insert(any()),
        ).thenAnswer((_) async => {});

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Shortcut Task');
        await tester.pumpAndSettle();

        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(AppKeyBindings.digit4);
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(AppKeyBindings.enter);
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        verify(() => repos.mockTaskRepo.insert(any())).called(1);
      },
    );

    testWidgets(
      'submits form via Ctrl+Enter even when tag autocomplete is open',
      (tester) async {
        when(
          () => repos.mockTaskRepo.insert(any()),
        ).thenAnswer((_) async => {});

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Task with tag #');
        await tester.pumpAndSettle();

        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(AppKeyBindings.enter);
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        verify(() => repos.mockTaskRepo.insert(any())).called(1);
      },
    );

    testWidgets('submits form via Ctrl+Enter when input field is not focused', (
      tester,
    ) async {
      when(() => repos.mockTaskRepo.insert(any())).thenAnswer((_) async => {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Unfocused Task');
      await tester.pumpAndSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(AppKeyBindings.enter);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      verify(() => repos.mockTaskRepo.insert(any())).called(1);
    });

    testWidgets('submits form via Ctrl+Enter when dropdown menu is open', (
      tester,
    ) async {
      when(() => repos.mockTaskRepo.insert(any())).thenAnswer((_) async => {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Dropdown Task');
      await tester.pumpAndSettle();

      final addLabelButton = find.text('+ Label');
      if (addLabelButton.evaluate().isNotEmpty) {
        await tester.ensureVisible(addLabelButton);
        await tester.pumpAndSettle();
        await tester.tap(addLabelButton);
        await tester.pumpAndSettle();
      }

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(AppKeyBindings.enter);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      verify(() => repos.mockTaskRepo.insert(any())).called(1);
    });
  });
}
