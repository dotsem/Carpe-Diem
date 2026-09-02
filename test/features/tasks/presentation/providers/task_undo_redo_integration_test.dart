import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
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

  group('Task Undo/Redo Integration Registrars', () {
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
      'reorderTask and bulkReorderTasks register commands and undo/redo cleanly',
      () async {
        final task = createTestTask(
          id: 't1',
          title: 'T1',
        ).copyWith(sortOrder: '0|i00000:');
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => task);

        final notifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await notifier.reorderTask(task, '0|i00005:');
        verify(() => mockTaskRepo.update(any())).called(1);
        expect(undoRedo.state.canUndo, isTrue);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(1);

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(1);
      },
    );

    test(
      'updateTask with deadline propagation reverts blocker on undo and reapplies on redo',
      () async {
        final blocker = createTestTask(
          id: 'b1',
          deadline: DateTime(2026, 12, 31),
        );
        final taskPrev = createTestTask(
          id: 't1',
          blockedById: 'b1',
          deadline: DateTime(2026, 12, 31),
        );
        final taskNext = taskPrev.copyWith(deadline: DateTime(2026, 10, 1));

        when(
          () => mockTaskRepo.getById('t1'),
        ).thenAnswer((_) async => taskPrev);
        when(() => mockTaskRepo.getById('b1')).thenAnswer((_) async => blocker);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await notifier.updateTask(taskNext);
        verify(() => mockTaskRepo.update(any())).called(2);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(2);

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(2);
      },
    );

    test(
      'deleteTask cascading subtasks deletes on execute, restores on undo, re-deletes on redo',
      () async {
        final parent = createTestTask(id: 'p1', title: 'Parent');
        final sub = createTestTask(id: 's1', parentId: 'p1', title: 'Sub');

        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [sub]);
        when(() => mockTaskRepo.getByParent('s1')).thenAnswer((_) async => []);
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await notifier.deleteTask(parent, deleteSubtasks: true);
        verify(() => mockTaskRepo.delete('s1')).called(1);
        verify(() => mockTaskRepo.delete('p1')).called(1);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.insert(any())).called(2);

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.delete('s1')).called(1);
        verify(() => mockTaskRepo.delete('p1')).called(1);
      },
    );

    test(
      'completeParentWithCascade undoes all completions and redoes all',
      () async {
        final parent = createTestTask(id: 'p1', status: TaskStatus.inProgress);
        final sub = createTestTask(
          id: 's1',
          parentId: 'p1',
          status: TaskStatus.todo,
        );
        final conflict = SubtaskCompletionConflict(
          parentTask: parent,
          incompleteSubtasks: [sub],
        );
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await notifier.completeParentWithCascade(conflict);
        verify(() => mockTaskRepo.update(any())).called(2);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(2);

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(2);
      },
    );

    test(
      'unScheduleTask with subtasks cascades undo and redo properly',
      () async {
        final parent = createTestTask(
          id: 'p1',
          scheduledDate: DateTime(2026, 8, 1),
        );
        final sub = createTestTask(
          id: 's1',
          parentId: 'p1',
          scheduledDate: DateTime(2026, 8, 1),
        );

        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [sub]);
        when(() => mockTaskRepo.getByParent('s1')).thenAnswer((_) async => []);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await notifier.unScheduleTask(
          parent,
          unscheduleChildren: true,
          resetStatus: true,
        );
        verify(() => mockTaskRepo.update(any())).called(2);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(2);

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(2);
      },
    );

    test('bulkUpdateTasks executes compound undo and redo', () async {
      final t1 = createTestTask(id: 't1', isUrgent: false);
      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      final undoRedo = container.read(undoRedoProvider.notifier);

      await notifier.bulkUpdateTasks(
        taskIds: ['t1'],
        updateUrgent: true,
        isUrgent: true,
      );
      verify(() => mockTaskRepo.update(any())).called(1);

      await undoRedo.undo();
      await Future.delayed(Duration.zero);
      verify(() => mockTaskRepo.update(any())).called(1);

      await undoRedo.redo();
      await Future.delayed(Duration.zero);
      verify(() => mockTaskRepo.update(any())).called(1);
    });

    test(
      'bulkDeleteTasks executes compound delete, re-inserts on undo, re-deletes on redo',
      () async {
        final t1 = createTestTask(id: 't1');
        when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
        when(() => mockTaskRepo.getByParent('t1')).thenAnswer((_) async => []);
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await notifier.bulkDeleteTasks(taskIds: ['t1']);
        verify(() => mockTaskRepo.delete('t1')).called(1);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.insert(any())).called(1);

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.delete('t1')).called(1);
      },
    );

    test(
      'importTasksFromMarkdown executes compound insert, deletes on undo, re-inserts on redo',
      () async {
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await notifier.importTasksFromMarkdown(
          markdown: '- [ ] Import Task 1\n- [ ] Import Task 2',
          projectId: null,
        );
        verify(() => mockTaskRepo.insert(any())).called(2);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.delete(any())).called(2);

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.insert(any())).called(2);
      },
    );
  });
}
