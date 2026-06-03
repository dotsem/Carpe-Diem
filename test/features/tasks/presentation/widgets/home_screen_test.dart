import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/presentation/screens/home_screen.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}
class MockProjectRepository extends Mock implements IProjectRepository {}
class MockLabelRepository extends Mock implements ILabelRepository {}
class MockHistoryRepository extends Mock implements IHistoryRepository {}
class MockSettingsRepository extends Mock implements ISettingsRepository {}

void main() {
  group('HomeScreen Widget Test', () {
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
      when(() => mockTaskRepo.getUnscheduled(prioritizeDeadlines: any(named: 'prioritizeDeadlines')))
          .thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
    });

    testWidgets('should render Home Screen details, DaySelector, and tasks list', (tester) async {
      final today = DateTime.now();
      final tasksList = [
        Task(id: 't-today-1', title: 'Code widget test', status: TaskStatus.todo, createdAt: today, scheduledDate: today),
      ];

      // Return tasks when loading for date
      when(() => mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines')))
          .thenAnswer((_) async => tasksList);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskRepo),
            projectRepositoryProvider.overrideWithValue(mockProjectRepo),
            labelRepositoryProvider.overrideWithValue(mockLabelRepo),
            historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
            settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );

      // Trigger initialization frame and async providers
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify page displays Today
      expect(find.text('Today'), findsOneWidget);

      // Verify the day selector is rendered
      expect(find.text('Today'), findsOneWidget); // Header
      expect(find.text('Add Task'), findsOneWidget);

      // Verify the loaded scheduled task card
      expect(find.text('Code widget test'), findsOneWidget);
    });
  });
}
