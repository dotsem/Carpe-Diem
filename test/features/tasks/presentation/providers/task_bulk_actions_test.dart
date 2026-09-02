import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('TaskBulkActions', () {
    late TestTaskRepositories repos;
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late ProviderContainer container;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
      mockTaskRepo = repos.mockTaskRepo;
      mockProjectRepo = repos.mockProjectRepo;
      container = repos.createContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('bulkUpdateTasks updates urgency, dates, and project', () async {
      final t1 = createTestTask(id: 't1', title: 'Task 1');
      final t2 = createTestTask(id: 't2', title: 'Task 2');

      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
      when(() => mockTaskRepo.getById('t2')).thenAnswer((_) async => t2);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      final newDate = DateTime(2026, 9, 20);

      await notifier.bulkUpdateTasks(
        taskIds: ['t1', 't2'],
        updateUrgent: true,
        isUrgent: true,
        updateScheduledDate: true,
        scheduledDate: newDate,
        updateProjectId: true,
        projectId: 'proj1',
      );

      verify(() => mockTaskRepo.update(any())).called(2);
      final undoRedo = container.read(undoRedoProvider);
      expect(undoRedo.canUndo, isTrue);
      expect(undoRedo.undoDescription, equals('Update 2 tasks'));
    });

    test('bulkUpdateTasks clears fields when clear flags are set', () async {
      final t1 = createTestTask(
        id: 't1',
        scheduledDate: DateTime.now(),
        projectId: 'proj1',
        blockedById: 'b1',
      );

      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.bulkUpdateTasks(
        taskIds: ['t1'],
        clearScheduledDate: true,
        clearProjectId: true,
        clearBlockedById: true,
      );

      verify(
        () => mockTaskRepo.update(
          any(
            that: isA<Task>()
                .having((t) => t.scheduledDate, 'scheduledDate', isNull)
                .having((t) => t.projectId, 'projectId', isNull)
                .having((t) => t.blockedById, 'blockedById', isNull),
          ),
        ),
      ).called(1);
    });

    test('bulkDeleteTasks deletes tasks and subtasks recursively', () async {
      final t1 = createTestTask(id: 't1');
      final sub1 = createTestTask(id: 's1', parentId: 't1');

      when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => t1);
      when(() => mockTaskRepo.getById('s1')).thenAnswer((_) async => sub1);
      when(
        () => mockTaskRepo.getByParent('t1'),
      ).thenAnswer((_) async => [sub1]);
      when(() => mockTaskRepo.getByParent('s1')).thenAnswer((_) async => []);
      when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

      final notifier = container.read(taskProvider.notifier);
      await notifier.bulkDeleteTasks(taskIds: ['t1']);

      verify(() => mockTaskRepo.delete('s1')).called(1);
      verify(() => mockTaskRepo.delete('t1')).called(1);
      final undoRedo = container.read(undoRedoProvider);
      expect(undoRedo.canUndo, isTrue);
      expect(undoRedo.undoDescription, equals('Delete 2 tasks'));
    });

    test(
      'importTasksFromMarkdown creates tasks with project deadline inheritance',
      () async {
        final projectDeadline = DateTime(2026, 12, 1);
        final project = Project(
          id: 'proj1',
          name: 'Project 1',
          color: Colors.blue,
          deadline: projectDeadline,
          createdAt: DateTime.now(),
        );

        when(
          () => mockProjectRepo.getById('proj1'),
        ).thenAnswer((_) async => project);
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});

        await container
            .read(settingsProvider.notifier)
            .setInheritProjectDeadline(true);

        final notifier = container.read(taskProvider.notifier);
        const md = '- [ ] Task from markdown 1\n- [x] Task from markdown 2';

        await notifier.importTasksFromMarkdown(
          markdown: md,
          projectId: 'proj1',
        );

        verify(
          () => mockTaskRepo.insert(
            any(
              that: isA<Task>()
                  .having((t) => t.projectId, 'projectId', 'proj1')
                  .having((t) => t.deadline, 'deadline', projectDeadline),
            ),
          ),
        ).called(2);

        final undoRedo = container.read(undoRedoProvider);
        expect(undoRedo.canUndo, isTrue);
        expect(undoRedo.undoDescription, equals('Import 2 tasks'));
      },
    );
  });
}
