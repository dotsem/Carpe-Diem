import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('TaskScheduleActions', () {
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

    test('rescheduleOverdue updates scheduled date of overdue task', () async {
      final task = createTestTask(
        id: 't1',
        scheduledDate: DateTime(2026, 1, 1),
      );
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      final newDate = DateTime(2026, 9, 10);
      await notifier.rescheduleOverdue(task, newDate);

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>()
                .having((t) => t.id, 'id', 't1')
                .having(
                  (t) => t.scheduledDate,
                  'scheduledDate',
                  newDate.normalize,
                ),
          ),
        ),
      ).called(1);
    });

    test('unScheduleTask without subtasks clears scheduledDate', () async {
      final task = createTestTask(
        id: 't1',
        scheduledDate: DateTime(2026, 8, 1),
        status: TaskStatus.inProgress,
      );
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.unScheduleTask(task, resetStatus: true);

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>()
                .having((t) => t.id, 'id', 't1')
                .having((t) => t.scheduledDate, 'date', isNull)
                .having((t) => t.status, 'status', TaskStatus.todo),
          ),
        ),
      ).called(1);
    });

    test('scheduleTasksForDate schedules bulk tasks', () async {
      final t1 = createTestTask(id: 't1');
      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
      when(() => mockTaskRepo.getByParent('t1')).thenAnswer((_) async => []);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      final date = DateTime(2026, 9, 15);
      await notifier.scheduleTasksForDate(['t1'], date);

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>()
                .having((t) => t.id, 'id', 't1')
                .having(
                  (t) => t.scheduledDate,
                  'scheduledDate',
                  date.normalize,
                ),
          ),
        ),
      ).called(1);
    });

    test('scheduleTasksForTomorrow schedules tasks for tomorrow', () async {
      final t1 = createTestTask(id: 't1');
      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
      when(() => mockTaskRepo.getByParent('t1')).thenAnswer((_) async => []);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.scheduleTasksForTomorrow(['t1']);

      final expectedDate = DateTime.now()
          .add(const Duration(days: 1))
          .normalize;
      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>()
                .having((t) => t.id, 'id', 't1')
                .having((t) => t.scheduledDate, 'date', expectedDate),
          ),
        ),
      ).called(1);
    });

    test(
      'scheduleTasksForNextDay schedules tasks for day after selected date',
      () async {
        final t1 = createTestTask(id: 't1');
        when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
        when(() => mockTaskRepo.getByParent('t1')).thenAnswer((_) async => []);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final selectedDate = DateTime(2026, 5, 10);
        await notifier.scheduleTasksForNextDay(['t1'], selectedDate);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 't1')
                  .having(
                    (t) => t.scheduledDate,
                    'date',
                    DateTime(2026, 5, 11).normalize,
                  ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'scheduleTasksForNextWorkDay schedules tasks for start of next week',
      () async {
        final t1 = createTestTask(id: 't1');
        when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
        when(() => mockTaskRepo.getByParent('t1')).thenAnswer((_) async => []);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.scheduleTasksForNextWorkDay(['t1']);

        verify(() => mockTaskRepo.update(any())).called(1);
      },
    );

    test(
      'pickAndScheduleRandomTask picks unblocked task and schedules for today',
      () async {
        final t1 = createTestTask(id: 't1', title: 'Pick Me');
        when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
        when(() => mockTaskRepo.getByParent('t1')).thenAnswer((_) async => []);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final picked = await notifier.pickAndScheduleRandomTask([t1]);

        expect(picked, isNotNull);
        expect(picked!.id, equals('t1'));
        verify(() => mockTaskRepo.update(any())).called(1);
      },
    );
  });
}
