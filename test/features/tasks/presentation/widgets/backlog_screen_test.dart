import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/presentation/screens/backlog_screen.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('tasks', () {
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late MockLabelRepository mockLabelRepo;
    late MockHistoryRepository mockHistoryRepo;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      mockTaskRepo = MockTaskRepository();
      mockProjectRepo = MockProjectRepository();
      mockLabelRepo = MockLabelRepository();
      mockHistoryRepo = MockHistoryRepository();
      mockSettingsRepo = MockSettingsRepository();

      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
    });

    testWidgets('should render Backlog Screen items and search inputs correctly', (tester) async {
      final backlogTasks = [
        Task(id: 't-backlog-1', title: 'Legacy code cleanup', status: TaskStatus.todo, createdAt: DateTime.now()),
      ];

      when(
        () => mockTaskRepo.getUnscheduled(prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => backlogTasks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskRepo),
            projectRepositoryProvider.overrideWithValue(mockProjectRepo),
            labelRepositoryProvider.overrideWithValue(mockLabelRepo),
            historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
            settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
          ],
          child: const MaterialApp(home: Scaffold(body: BacklogScreen())),
        ),
      );

      // Trigger initialization and loaders
      await tester.pumpAndSettle();

      // Verify header texts are rendered
      expect(find.text('Backlog'), findsOneWidget);
      expect(find.text('Tasks without a scheduled date'), findsOneWidget);

      // Verify the task card is loaded from unscheduled tasks
      expect(find.text('Legacy code cleanup'), findsOneWidget);

      // Verify search and add buttons exist
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
    });
  });
}
