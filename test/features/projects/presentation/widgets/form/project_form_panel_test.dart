import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/form/project_form_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      Project(
        id: '',
        name: '',
        color: Colors.red,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  group('ProjectFormPanel', () {
    late TestTaskRepositories repos;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    Widget buildTestWidget({Project? project}) {
      return ProviderScope(
        overrides: repos.providerOverrides,
        child: MaterialApp(
          home: Scaffold(body: ProjectFormPanel(project: project)),
        ),
      );
    }

    testWidgets('shows validation error when submitting empty project name', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      expect(find.text('Project name is required'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'New Project Title');
      await tester.pumpAndSettle();

      expect(find.text('Project name is required'), findsNothing);
    });

    testWidgets(
      'supports keyboard shortcuts for urgency toggle and form submission',
      (tester) async {
        when(
          () => repos.mockProjectRepo.insert(any()),
        ).thenAnswer((_) async => 'p_new');

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'Shortcut Project',
        );
        await tester.pumpAndSettle();

        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(AppKeyBindings.digit2);
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(AppKeyBindings.enter);
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        verify(() => repos.mockProjectRepo.insert(any())).called(1);
      },
    );

    testWidgets(
      'submits project form via Ctrl+Enter when input field is not focused',
      (tester) async {
        when(
          () => repos.mockProjectRepo.insert(any()),
        ).thenAnswer((_) async => 'p_new');

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'Unfocused Project',
        );
        await tester.pumpAndSettle();

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(AppKeyBindings.enter);
        await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        verify(() => repos.mockProjectRepo.insert(any())).called(1);
      },
    );
  });
}
