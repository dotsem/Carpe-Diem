import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/actions/task_hierarchy_actions.dart';
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

  group('TaskHierarchyActions', () {
    late MockTaskRepository mockTaskRepo;
    late ProviderContainer container;

    setUp(() {
      final repos = TestTaskRepositories();
      repos.setupDefaultStubs();
      when(() => repos.mockTaskRepo.update(any())).thenAnswer((_) async => {});
      when(() => repos.mockTaskRepo.insert(any())).thenAnswer((_) async => {});
      mockTaskRepo = repos.mockTaskRepo;
      container = repos.createContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('reparentTasks assigns new parentId and computes sortOrder', () async {
      final parent = Task(
        id: 'parent_1',
        title: 'Parent Task',
        projectId: 'project_alpha',
        createdAt: DateTime.now(),
      );
      final taskToReparent = Task(
        id: 'task_1',
        title: 'Idea Task',
        projectId: 'different_project',
        createdAt: DateTime.now(),
      );

      when(
        () => mockTaskRepo.getById('parent_1'),
      ).thenAnswer((_) async => parent);
      when(
        () => mockTaskRepo.getById('task_1'),
      ).thenAnswer((_) async => taskToReparent);
      when(
        () => mockTaskRepo.getByParent('parent_1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getByParent('task_1'),
      ).thenAnswer((_) async => []);

      final notifier = container.read(taskProvider.notifier);
      await notifier.reparentTasks(
        taskIds: ['task_1'],
        newParentId: 'parent_1',
      );

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>()
                .having((t) => t.id, 'id', 'task_1')
                .having((t) => t.parentId, 'parentId', 'parent_1')
                .having((t) => t.projectId, 'projectId', 'project_alpha'),
          ),
        ),
      ).called(1);
    });

    test(
      'reparentTasks with null parentId detaches child back to root',
      () async {
        final subtask = Task(
          id: 'sub_1',
          title: 'Subtask 1',
          parentId: 'parent_1',
          createdAt: DateTime.now(),
        );

        when(
          () => mockTaskRepo.getById('sub_1'),
        ).thenAnswer((_) async => subtask);
        when(
          () => mockTaskRepo.getUnscheduled(
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
            prioritizeOverdue: any(named: 'prioritizeOverdue'),
          ),
        ).thenAnswer((_) async => []);

        final notifier = container.read(taskProvider.notifier);
        await notifier.reparentTasks(taskIds: ['sub_1'], newParentId: null);

        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'sub_1')
                  .having((t) => t.parentId, 'parentId', isNull),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'createParentWithSubtasks creates parent and reparents children under compound command',
      () async {
        final task1 = Task(
          id: 't_1',
          title: 'Task 1',
          createdAt: DateTime.now(),
        );
        final task2 = Task(
          id: 't_2',
          title: 'Task 2',
          createdAt: DateTime.now(),
        );

        when(() => mockTaskRepo.getById('t_1')).thenAnswer((_) async => task1);
        when(() => mockTaskRepo.getById('t_2')).thenAnswer((_) async => task2);
        when(() => mockTaskRepo.getByParent('t_1')).thenAnswer((_) async => []);
        when(() => mockTaskRepo.getByParent('t_2')).thenAnswer((_) async => []);

        final notifier = container.read(taskProvider.notifier);
        await notifier.createParentWithSubtasks(
          title: 'Grouped Parent',
          childTaskIds: ['t_1', 't_2'],
          projectId: 'project_omega',
        );

        // Verify parent was created
        verify(
          () => mockTaskRepo.insert(
            any(
              that: isA<Task>()
                  .having((t) => t.title, 'title', 'Grouped Parent')
                  .having((t) => t.parentId, 'parentId', isNull)
                  .having((t) => t.projectId, 'projectId', 'project_omega'),
            ),
          ),
        ).called(1);

        // Verify both children updated with a non-null parentId and inherited projectId
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 't_1')
                  .having((t) => t.parentId, 'parentId', isNotNull)
                  .having((t) => t.projectId, 'projectId', 'project_omega'),
            ),
          ),
        ).called(1);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 't_2')
                  .having((t) => t.parentId, 'parentId', isNotNull)
                  .having((t) => t.projectId, 'projectId', 'project_omega'),
            ),
          ),
        ).called(1);

        // Test single undo reverts all changes
        final undoRedo = container.read(undoRedoProvider.notifier);
        await undoRedo.undo();
        await Future.delayed(Duration.zero);

        // Parent should be deleted
        verify(() => mockTaskRepo.delete(any())).called(1);
        // Children should be restored to parentId == null
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 't_1')
                  .having((t) => t.parentId, 'parentId', isNull),
            ),
          ),
        ).called(1);
      },
    );

    test('reparentTasks skips tasks that already have subtasks', () async {
      final parent = Task(
        id: 'parent_1',
        title: 'Parent Task',
        createdAt: DateTime.now(),
      );
      final taskWithChild = Task(
        id: 'parent_2',
        title: 'Task with subtask',
        createdAt: DateTime.now(),
      );
      final existingSubtask = Task(
        id: 'sub_x',
        title: 'Existing Child',
        parentId: 'parent_2',
        createdAt: DateTime.now(),
      );

      when(
        () => mockTaskRepo.getById('parent_1'),
      ).thenAnswer((_) async => parent);
      when(
        () => mockTaskRepo.getById('parent_2'),
      ).thenAnswer((_) async => taskWithChild);
      when(
        () => mockTaskRepo.getByParent('parent_1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getByParent('parent_2'),
      ).thenAnswer((_) async => [existingSubtask]);

      final notifier = container.read(taskProvider.notifier);
      await notifier.reparentTasks(
        taskIds: ['parent_2'],
        newParentId: 'parent_1',
      );

      // Verify taskWithChild was NOT updated because it has subtasks
      verifyNever(() => mockTaskRepo.update(any()));
    });
  });
}
