import 'package:carpe_diem/features/tasks/data/models/task.dart';
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

  group('tasks scheduling cascade', () {
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

    test(
      'scheduleTasksForToday cascades date to unscheduled child subtasks',
      () async {
        final parent = createTestTask(id: 'p1', title: 'Parent');
        final unscheduledSubtask = createTestTask(
          id: 'sub1',
          title: 'Sub 1',
          parentId: 'p1',
          scheduledDate: null,
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [unscheduledSubtask]);
        when(
          () => mockTaskRepo.getByParent('sub1'),
        ).thenAnswer((_) async => []);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.scheduleTasksForToday(['p1']);

        verify(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'p1')),
          ),
        ).called(1);
        verify(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'sub1')),
          ),
        ).called(1);
      },
    );

    test(
      'scheduleTaskWithCascade parent only does not affect subtasks',
      () async {
        final parent = createTestTask(id: 'p1', title: 'Parent');
        final subtask = createTestTask(
          id: 'sub1',
          title: 'Sub 1',
          parentId: 'p1',
          scheduledDate: null,
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.scheduleTaskWithCascade(
          parent,
          DateTime(2026, 10, 1),
          cascadeChildren: false,
        );

        verify(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'p1')),
          ),
        ).called(1);
        verifyNever(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'sub1')),
          ),
        );
      },
    );

    test(
      'unScheduleTask with unscheduleChildren: true unschedules parent and scheduled subtasks',
      () async {
        final parent = createTestTask(
          id: 'p1',
          title: 'Parent',
          scheduledDate: DateTime.now(),
        );
        final subtask = createTestTask(
          id: 'sub1',
          title: 'Sub 1',
          parentId: 'p1',
          scheduledDate: DateTime.now(),
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.unScheduleTask(parent, unscheduleChildren: true);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'p1')
                  .having((t) => t.scheduledDate, 'date', isNull),
            ),
          ),
        ).called(1);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'sub1')
                  .having((t) => t.scheduledDate, 'date', isNull),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'deleteTask with deleteSubtasks: false clears parentId on subtasks',
      () async {
        final parent = createTestTask(id: 'p1', title: 'Parent');
        final subtask = createTestTask(
          id: 'sub1',
          title: 'Sub 1',
          parentId: 'p1',
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.deleteTask(parent, deleteSubtasks: false);

        verify(() => mockTaskRepo.delete('p1')).called(1);
        verifyNever(() => mockTaskRepo.delete('sub1'));
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'sub1')
                  .having((t) => t.parentId, 'parentId', isNull),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'scheduleTaskWithCascade with cascadeChildren: true schedules parent and incomplete subtasks',
      () async {
        final parent = createTestTask(id: 'p1', title: 'Parent');
        final subtask = createTestTask(
          id: 'sub1',
          title: 'Sub 1',
          parentId: 'p1',
          scheduledDate: null,
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final targetDate = DateTime(2026, 11, 15);
        await notifier.scheduleTaskWithCascade(
          parent,
          targetDate,
          cascadeChildren: true,
        );

        verify(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'p1')),
          ),
        ).called(1);
        verify(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'sub1')),
          ),
        ).called(1);
      },
    );

    test(
      'deleteTask with deleteSubtasks: true deletes parent and all subtasks',
      () async {
        final parent = createTestTask(id: 'p1', title: 'Parent');
        final subtask = createTestTask(
          id: 'sub1',
          title: 'Sub 1',
          parentId: 'p1',
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.deleteTask(parent, deleteSubtasks: true);

        verify(() => mockTaskRepo.delete('p1')).called(1);
        verify(() => mockTaskRepo.delete('sub1')).called(1);
      },
    );
  });
}
