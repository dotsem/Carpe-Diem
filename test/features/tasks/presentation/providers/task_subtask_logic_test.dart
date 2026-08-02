import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
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

  group('tasks', () {
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
      'addTask with parentId inherits scheduledDate and projectId from parent',
      () async {
        final parentDate = DateTime(2026, 8, 10);
        final parent = createTestTask(
          id: 'p1',
          title: 'Parent',
          scheduledDate: parentDate,
          projectId: 'proj1',
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.addTask(title: 'Subtask', parentId: 'p1');

        verify(
          () => mockTaskRepo.insert(
            any(
              that: isA<Task>()
                  .having((t) => t.parentId, 'parentId', 'p1')
                  .having(
                    (t) => t.scheduledDate,
                    'scheduledDate',
                    DateTime(2026, 8, 10),
                  )
                  .having((t) => t.projectId, 'projectId', 'proj1'),
            ),
          ),
        ).called(1);
      },
    );

    test('checkSubtaskConflict identifies incomplete subtasks', () async {
      final parent = createTestTask(id: 'p1', title: 'Parent');
      final sub1 = createTestTask(id: 's1', title: 'Sub 1', parentId: 'p1');
      final sub2 = createTestTask(
        id: 's2',
        title: 'Sub 2',
        parentId: 'p1',
        status: TaskStatus.done,
      );

      when(
        () => mockTaskRepo.getByParent('p1'),
      ).thenAnswer((_) async => [sub1, sub2]);

      final notifier = container.read(taskProvider.notifier);
      final conflict = await notifier.checkSubtaskConflict(parent);

      expect(conflict, isNotNull);
      expect(conflict!.incompleteSubtasks.length, equals(1));
      expect(conflict.incompleteSubtasks.first.id, equals('s1'));
    });

    test(
      'toggleComplete from inProgress detects conflict when subtasks incomplete',
      () async {
        final parent = createTestTask(
          id: 'p1',
          title: 'Parent',
          status: TaskStatus.inProgress,
        );
        final sub1 = createTestTask(id: 's1', title: 'Sub 1', parentId: 'p1');

        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [sub1]);

        final notifier = container.read(taskProvider.notifier);
        final conflict = await notifier.toggleComplete(parent);

        expect(conflict, isA<SubtaskCompletionConflict>());
        expect(conflict!.parentTask.id, equals('p1'));
      },
    );

    test(
      'completeParentWithCascade marks parent and all incomplete subtasks done',
      () async {
        final parent = createTestTask(
          id: 'p1',
          title: 'Parent',
          status: TaskStatus.inProgress,
        );
        final sub1 = createTestTask(id: 's1', title: 'Sub 1', parentId: 'p1');

        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final conflict = SubtaskCompletionConflict(
          parentTask: parent,
          incompleteSubtasks: [sub1],
        );
        final notifier = container.read(taskProvider.notifier);
        await notifier.completeParentWithCascade(conflict);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 's1')
                  .having((t) => t.status, 'status', TaskStatus.done),
            ),
          ),
        ).called(1);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'p1')
                  .having((t) => t.status, 'status', TaskStatus.done),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'completeParentOnly completes parent without completing subtasks',
      () async {
        final parent = createTestTask(
          id: 'p1',
          title: 'Parent',
          status: TaskStatus.inProgress,
        );

        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.completeParentOnly(parent);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'p1')
                  .having((t) => t.status, 'status', TaskStatus.done),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'completing subtask auto-completes parent when all siblings done',
      () async {
        final parent = createTestTask(
          id: 'p1',
          title: 'Parent',
          status: TaskStatus.inProgress,
        );
        final sub1 = createTestTask(
          id: 's1',
          title: 'Sub 1',
          parentId: 'p1',
          status: TaskStatus.done,
        );
        final sub2 = createTestTask(
          id: 's2',
          title: 'Sub 2',
          parentId: 'p1',
          status: TaskStatus.inProgress,
        );

        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.getByParent('p1')).thenAnswer(
          (_) async => [sub1, sub2.copyWith(status: TaskStatus.done)],
        );
        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);

        final notifier = container.read(taskProvider.notifier);
        await notifier.completeTask(sub2);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'p1')
                  .having((t) => t.status, 'status', TaskStatus.done),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'getAllSubtasksFromRepo recursively collects all descendant subtasks',
      () async {
        final child = createTestTask(id: 'c1', title: 'Child', parentId: 'p1');
        final grandChild = createTestTask(
          id: 'gc1',
          title: 'Grandchild',
          parentId: 'c1',
        );

        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [child]);
        when(
          () => mockTaskRepo.getByParent('c1'),
        ).thenAnswer((_) async => [grandChild]);
        when(() => mockTaskRepo.getByParent('gc1')).thenAnswer((_) async => []);

        final notifier = container.read(taskProvider.notifier);
        final subtasks = await notifier.getAllSubtasksFromRepo('p1');

        expect(subtasks.length, equals(2));
        expect(subtasks.map((t) => t.id), containsAll(['c1', 'gc1']));
      },
    );

    test('deleteTask recursively deletes subtasks and parent', () async {
      final parent = createTestTask(id: 'p1', title: 'Parent');
      final child = createTestTask(id: 'c1', title: 'Child', parentId: 'p1');

      when(
        () => mockTaskRepo.getByParent('p1'),
      ).thenAnswer((_) async => [child]);
      when(() => mockTaskRepo.getByParent('c1')).thenAnswer((_) async => []);
      when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.deleteTask(parent);

      verify(() => mockTaskRepo.delete('c1')).called(1);
      verify(() => mockTaskRepo.delete('p1')).called(1);
    });

    test(
      'bulkDeleteTasks recursively deletes subtasks of all target tasks',
      () async {
        final sub = createTestTask(id: 'sub1', title: 'Sub', parentId: 'p1');

        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [sub]);
        when(
          () => mockTaskRepo.getByParent('sub1'),
        ).thenAnswer((_) async => []);
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.bulkDeleteTasks(['p1']);

        verify(() => mockTaskRepo.delete('sub1')).called(1);
        verify(() => mockTaskRepo.delete('p1')).called(1);
      },
    );
  });
}
