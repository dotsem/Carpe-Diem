import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}

class MockProjectRepository extends Mock implements IProjectRepository {}

class MockHistoryRepository extends Mock implements IHistoryRepository {}

class MockSettingsRepository extends Mock implements ISettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('TaskNotifier', () {
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late MockHistoryRepository mockHistoryRepo;
    late MockSettingsRepository mockSettingsRepo;
    late ProviderContainer container;

    setUp(() {
      mockTaskRepo = MockTaskRepository();
      mockProjectRepo = MockProjectRepository();
      mockHistoryRepo = MockHistoryRepository();
      mockSettingsRepo = MockSettingsRepository();

      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          projectRepositoryProvider.overrideWithValue(mockProjectRepo),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should load tasks and overdue tasks for a given date', () async {
      final date = DateTime(2026, 6, 1);
      final list = [Task(id: 't1', title: 'Task A', scheduledDate: date, createdAt: DateTime.now())];
      final overdue = [
        Task(
          id: 't2',
          title: 'Task B',
          scheduledDate: date.subtract(const Duration(days: 2)),
          createdAt: DateTime.now(),
        ),
      ];

      when(
        () => mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => list);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => overdue);
      when(
        () => mockTaskRepo.getUnscheduled(prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);

      await container.read(taskProvider.notifier).loadTasksForDate(date);

      final state = container.read(taskProvider);
      expect(state.tasks.length, equals(1));
      expect(state.tasks.first.id, equals('t1'));
      expect(state.overdueTasks.length, equals(1));
      expect(state.overdueTasks.first.id, equals('t2'));
    });

    test('should add task, call insert repository, and refresh UI list state', () async {
      when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});
      when(
        () => mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getUnscheduled(prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);

      final notifier = container.read(taskProvider.notifier);
      await notifier.addTask(title: 'Learn Riverpod Testing', description: 'Read the docs', priority: Priority.high);

      verify(() => mockTaskRepo.insert(any())).called(1);
    });

    test('should change task status and call repository update', () async {
      final task = Task(id: 't1', title: 'Task', createdAt: DateTime.now());

      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
      when(
        () => mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getUnscheduled(prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);

      await container.read(taskProvider.notifier).updateTaskStatus(task, TaskStatus.inProgress);

      verify(
        () => mockTaskRepo.update(any(that: isA<Task>().having((t) => t.status, 'status', TaskStatus.inProgress))),
      ).called(1);
    });
  });
}
