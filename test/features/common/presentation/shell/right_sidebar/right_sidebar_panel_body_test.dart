import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_panel_body.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/task_form_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/task_test_helpers.dart';

void main() {
  group('RightSidebarPanelBody', () {
    late TestTaskRepositories repos;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    Widget buildTestWidget(RightSidebarPanel panel) {
      return ProviderScope(
        overrides: repos.providerOverrides,
        child: MaterialApp(
          home: Scaffold(body: RightSidebarPanelBody(panel: panel)),
        ),
      );
    }

    testWidgets('assigns distinct ValueKeys when switching between EditTaskPanels', (tester) async {
      final task1 = createTestTask(id: 'task_1', title: 'First Task Title');
      final task2 = createTestTask(id: 'task_2', title: 'Second Task Title');

      when(
        () => repos.mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => [task1, task2]);

      await tester.pumpWidget(buildTestWidget(const EditTaskPanel('task_1')));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(RightSidebarPanelBody)));
      await container.read(taskProvider.notifier).loadTasksForDate(DateTime.now());
      await tester.pumpAndSettle();

      final panel1 = tester.widget<TaskFormPanel>(find.byType(TaskFormPanel));
      expect(panel1.key, equals(const ValueKey('edit_task_task_1')));

      await tester.pumpWidget(buildTestWidget(const EditTaskPanel('task_2')));
      await tester.pumpAndSettle();

      final panel2 = tester.widget<TaskFormPanel>(find.byType(TaskFormPanel));
      expect(panel2.key, equals(const ValueKey('edit_task_task_2')));
      expect(panel1.key, isNot(equals(panel2.key)));
    });
  });
}
