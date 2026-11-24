import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/task_draft.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('TaskNotifier Core', () {
    late TestTaskRepositories repos;
    late MockTaskRepository mockTaskRepo;
    late ProviderContainer container;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
      mockTaskRepo = repos.mockTaskRepo;
      container = repos.createContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('loadTasksForDate loads tasks and overdue tasks', () async {
      final date = DateTime(2026, 6);
      final list = [createTestTask(scheduledDate: date)];
      final overdue = [createTestTask(id: 't2')];

      when(
        () => mockTaskRepo.getByDate(
          any(),
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
          prioritizeOverdue: any(named: 'prioritizeOverdue'),
        ),
      ).thenAnswer((_) async => list);
      when(
        () => mockTaskRepo.getOverdue(any()),
      ).thenAnswer((_) async => overdue);

      final notifier = container.read(taskProvider.notifier);
      await notifier.loadTasksForDate(date);

      final state = container.read(taskProvider);
      expect(state.tasks.length, equals(1));
      expect(state.overdueTasks.length, equals(1));
    });

    test('loadUnscheduledTasks loads unscheduled list into state', () async {
      final unscheduled = [createTestTask(id: 'u1')];
      when(
        () => mockTaskRepo.getUnscheduled(
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
          prioritizeOverdue: any(named: 'prioritizeOverdue'),
        ),
      ).thenAnswer((_) async => unscheduled);

      final notifier = container.read(taskProvider.notifier);
      await notifier.loadUnscheduledTasks();

      final state = container.read(taskProvider);
      expect(state.unscheduledTasks.length, equals(1));
      expect(state.unscheduledTasks.first.id, equals('u1'));
    });

    test(
      'changing task preferences does not reset loaded task state',
      () async {
        final date = DateTime(2026, 6);
        final loaded = createTestTask(id: 'kept', scheduledDate: date);
        when(
          () => mockTaskRepo.getByDate(
            any(),
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
            prioritizeOverdue: any(named: 'prioritizeOverdue'),
          ),
        ).thenAnswer((_) async => [loaded]);

        await container.read(taskProvider.notifier).loadTasksForDate(date);
        await container
            .read(settingsProvider.notifier)
            .setPrioritizeDeadlines(false);

        expect(container.read(taskProvider).tasks.single.id, 'kept');
      },
    );

    test('addTask creates task and refreshes state', () async {
      when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.addTask(
        const TaskDraft(title: 'New Task', isUrgent: true),
      );

      verify(() => mockTaskRepo.insert(any())).called(1);
    });

    test('updateTask updates repository item', () async {
      final task = createTestTask(title: 'Task Original');
      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => task);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.updateTask(task.copyWith(title: 'Task Updated'));

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>().having((t) => t.title, 'title', 'Task Updated'),
          ),
        ),
      ).called(1);
    });

    test('getters and a missing task update are safe', () async {
      when(() => mockTaskRepo.getById('missing')).thenAnswer((_) async => null);
      final notifier = container.read(taskProvider.notifier);

      expect(notifier.tasksState.tasks, isEmpty);
      expect(notifier.settings, isA<SettingsState>());
      expect(notifier.projectRepo, same(repos.mockProjectRepo));
      await notifier.updateTask(createTestTask(id: 'missing'));

      verifyNever(() => mockTaskRepo.update(any()));
    });

    test('deleteTask deletes task from repository', () async {
      final task = createTestTask();
      when(() => mockTaskRepo.delete('t1')).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.deleteTask(task);

      verify(() => mockTaskRepo.delete('t1')).called(1);
    });

    test('reorderTask updates sortOrder optimistically and persists', () async {
      final task = createTestTask().copyWith(sortOrder: '0|i00000:');
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.reorderTask(task, '0|i00010:');

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>().having(
              (t) => t.sortOrder,
              'sortOrder',
              '0|i00010:',
            ),
          ),
        ),
      ).called(1);
    });

    test('reorderTask can update plan sort order', () async {
      final task = createTestTask();
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async {});

      await container
          .read(taskProvider.notifier)
          .reorderTask(task, 'plan', isPlanOrder: true);

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>().having(
              (t) => t.planSortOrder,
              'planSortOrder',
              'plan',
            ),
          ),
        ),
      ).called(1);
    });

    test('bulkReorderTasks updates multiple tasks', () async {
      final t1 = createTestTask();
      final t2 = createTestTask(id: 't2');
      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
      when(() => mockTaskRepo.getById('t2')).thenAnswer((_) async => t2);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.bulkReorderTasks({'t1': '0|i00001:', 't2': '0|i00002:'});

      verify(() => mockTaskRepo.update(any())).called(2);
    });

    test('updateTaskStatus and startTask update status in repo', () async {
      final task = createTestTask();
      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => task);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.startTask(task);

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>().having(
              (t) => t.status,
              'status',
              TaskStatus.inProgress,
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'toggleComplete transitions from todo to inProgress, and done to todo',
      () async {
        final todoTask = createTestTask();
        final doneTask = createTestTask(id: 't2', status: TaskStatus.done);
        when(() => mockTaskRepo.getById(any())).thenAnswer((_) async => null);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.toggleComplete(todoTask);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>().having(
                (t) => t.status,
                'status',
                TaskStatus.inProgress,
              ),
            ),
          ),
        ).called(1);

        await notifier.toggleComplete(doneTask);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>().having(
                (t) => t.status,
                'status',
                TaskStatus.todo,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'toggleComplete transitions inProgress to review when reviewState is enabled',
      () async {
        await container.read(settingsProvider.notifier).setReviewState(true);
        final inProgressTask = createTestTask(status: TaskStatus.inProgress);
        when(() => mockTaskRepo.getById(any())).thenAnswer((_) async => null);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.toggleComplete(inProgressTask);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>().having(
                (t) => t.status,
                'status',
                TaskStatus.review,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'toggleComplete transitions inProgress to done when reviewState is disabled',
      () async {
        await container.read(settingsProvider.notifier).setReviewState(false);
        final inProgressTask = createTestTask(status: TaskStatus.inProgress);
        when(() => mockTaskRepo.getById(any())).thenAnswer((_) async => null);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.toggleComplete(inProgressTask);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>().having(
                (t) => t.status,
                'status',
                TaskStatus.done,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'toggleComplete transitions review to done when reviewState is disabled',
      () async {
        await container.read(settingsProvider.notifier).setReviewState(false);
        final reviewTask = createTestTask(status: TaskStatus.review);
        when(() => mockTaskRepo.getById(any())).thenAnswer((_) async => null);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.toggleComplete(reviewTask);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>().having(
                (t) => t.status,
                'status',
                TaskStatus.done,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'toggleComplete transitions review to done when reviewState is enabled',
      () async {
        await container.read(settingsProvider.notifier).setReviewState(true);
        final reviewTask = createTestTask(status: TaskStatus.review);
        when(() => mockTaskRepo.getById(any())).thenAnswer((_) async => null);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.toggleComplete(reviewTask);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>().having(
                (t) => t.status,
                'status',
                TaskStatus.done,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('getTasksForProject fetches tasks by project id', () async {
      when(
        () => mockTaskRepo.getByProject(
          'proj1',
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        ),
      ).thenAnswer((_) async => [createTestTask(id: 'p1')]);

      final notifier = container.read(taskProvider.notifier);
      final tasks = await notifier.getTasksForProject('proj1');

      expect(tasks.length, equals(1));
      verify(
        () => mockTaskRepo.getByProject(
          'proj1',
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        ),
      ).called(1);
    });

    test('toggleComplete cancels an already pending completion', () async {
      final task = createTestTask(status: TaskStatus.inProgress);
      final notifier = container.read(taskProvider.notifier);
      container
          .read(taskTimerProvider.notifier)
          .startPending(task.id, 30, () async {});

      await notifier.toggleComplete(task, useTimer: true);

      expect(
        container.read(taskTimerProvider.notifier).isTaskPending(task.id),
        isFalse,
      );
    });

    test(
      'exposes all nested subtasks and completes a parent directly',
      () async {
        final parent = createTestTask(id: 'parent');
        final child = createTestTask(id: 'child', parentId: 'parent');
        final grandchild = createTestTask(id: 'grand', parentId: 'child');
        when(
          () => mockTaskRepo.getByDate(
            any(),
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
            prioritizeOverdue: any(named: 'prioritizeOverdue'),
          ),
        ).thenAnswer((_) async => [parent, child, grandchild]);
        when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
        when(
          () => mockTaskRepo.getById('parent'),
        ).thenAnswer((_) async => parent);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async {});
        final notifier = container.read(taskProvider.notifier);
        await notifier.loadTasksForDate(DateTime(2026));

        expect(notifier.getAllSubtasks('parent').map((t) => t.id), [
          'child',
          'grand',
        ]);
        await notifier.completeParentOnly(parent);
        verify(() => mockTaskRepo.update(any())).called(1);
      },
    );

    test(
      'toggleComplete with a timer holds the completion until it fires',
      () async {
        final task = createTestTask(status: TaskStatus.inProgress);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
        final notifier = container.read(taskProvider.notifier);
        final timer = container.read(taskTimerProvider.notifier);

        await notifier.toggleComplete(task, useTimer: true);

        expect(timer.isTaskPending(task.id), isTrue);
        verifyNever(() => mockTaskRepo.update(any()));

        await notifier.toggleComplete(task);
        expect(timer.isTaskPending(task.id), isFalse);
      },
    );

    test('toggleComplete completes the task once the timer fires', () async {
      final task = createTestTask(status: TaskStatus.inProgress);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
      await container.read(settingsProvider.notifier).setTaskCompletionDelay(0);

      await container
          .read(taskProvider.notifier)
          .toggleComplete(task, useTimer: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>().having(
              (t) => t.status,
              'status',
              TaskStatus.done,
            ),
          ),
        ),
      ).called(1);
      expect(
        container.read(taskTimerProvider.notifier).isTaskPending(task.id),
        isFalse,
      );
    });
  });
}
