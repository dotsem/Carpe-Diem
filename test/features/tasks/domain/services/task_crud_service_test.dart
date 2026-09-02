import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_crud_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskCrudService', () {
    late MockTaskRepository mockRepo;
    const defaultSettings = SettingsState({});

    setUp(() {
      mockRepo = MockTaskRepository();
      when(
        () => mockRepo.getUnscheduled(
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
          prioritizeOverdue: any(named: 'prioritizeOverdue'),
        ),
      ).thenAnswer((_) async => []);
    });

    group('buildNewTask', () {
      test('builds independent task with default placement', () async {
        final task = await TaskCrudService.buildNewTask(
          repo: mockRepo,
          settings: defaultSettings,
          title: 'My Task',
          description: 'A description',
          labelIds: ['lbl1'],
          tagIds: ['tag1'],
        );

        expect(task.id, isNotEmpty);
        expect(task.title, equals('My Task'));
        expect(task.description, equals('A description'));
        expect(task.labelIds, equals(['lbl1']));
        expect(task.tagIds, equals(['tag1']));
        expect(task.sortOrder, isNotEmpty);
      });

      test(
        'subtask inherits scheduledDate and projectId from parent',
        () async {
          final parentDate = DateTime(2026, 6, 1);
          final parent = createTestTask(
            id: 'p1',
            scheduledDate: parentDate,
            projectId: 'proj1',
          );
          when(() => mockRepo.getById('p1')).thenAnswer((_) async => parent);
          when(() => mockRepo.getByParent('p1')).thenAnswer((_) async => []);

          final task = await TaskCrudService.buildNewTask(
            repo: mockRepo,
            settings: defaultSettings,
            title: 'Child Task',
            parentId: 'p1',
          );

          expect(task.parentId, equals('p1'));
          expect(task.scheduledDate, equals(parentDate.normalize));
          expect(task.projectId, equals('proj1'));
        },
      );

      test('explicit dates and projectId override parent properties', () async {
        final parent = createTestTask(
          id: 'p1',
          scheduledDate: DateTime(2026, 6, 1),
          projectId: 'proj1',
        );
        when(() => mockRepo.getById('p1')).thenAnswer((_) async => parent);
        when(() => mockRepo.getByParent('p1')).thenAnswer((_) async => []);

        final explicitDate = DateTime(2026, 7, 1);
        final task = await TaskCrudService.buildNewTask(
          repo: mockRepo,
          settings: defaultSettings,
          title: 'Explicit Child Task',
          parentId: 'p1',
          scheduledDate: explicitDate,
          projectId: 'proj2',
        );

        expect(task.scheduledDate, equals(explicitDate.normalize));
        expect(task.projectId, equals('proj2'));
      });

      test('placement urgent marks isUrgent true', () async {
        final task = await TaskCrudService.buildNewTask(
          repo: mockRepo,
          settings: defaultSettings,
          title: 'Urgent Task',
          placement: TaskPlacement.urgent,
        );

        expect(task.isUrgent, isTrue);
      });
    });

    group('resolveUpdatedTask', () {
      test('returns unchanged task when placement is null', () async {
        final task = createTestTask(id: 't1', title: 'Task 1');
        final resolved = await TaskCrudService.resolveUpdatedTask(
          repo: mockRepo,
          settings: defaultSettings,
          task: task,
          placement: null,
        );
        expect(resolved, equals(task));
      });

      test('recalculates sortOrder when placement is provided', () async {
        final existingTask = createTestTask(
          id: 't1',
        ).copyWith(sortOrder: '0|i00000:');
        when(
          () => mockRepo.getUnscheduled(
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
            prioritizeOverdue: any(named: 'prioritizeOverdue'),
          ),
        ).thenAnswer((_) async => [existingTask]);

        final updatedTask = createTestTask(
          id: 't2',
        ).copyWith(sortOrder: '0|i00000:');
        final resolved = await TaskCrudService.resolveUpdatedTask(
          repo: mockRepo,
          settings: defaultSettings,
          task: updatedTask,
          placement: TaskPlacement.bottom,
        );

        expect(resolved.sortOrder, isNot(equals('0|i00000:')));
      });
    });

    group('buildCreateWithPropagationCommand', () {
      test(
        'returns single CreateCommand without deadline propagation',
        () async {
          final task = createTestTask(id: 't1', title: 'Task');
          final cmd = await TaskCrudService.buildCreateWithPropagationCommand(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );
          expect(cmd, isA<CreateCommand<Task>>());
          expect((cmd as CreateCommand<Task>).id, equals('t1'));
        },
      );

      test(
        'returns CompoundCommand with blocker updates when propagation occurs',
        () async {
          final task = createTestTask(
            id: 't1',
            title: 'Task',
            deadline: DateTime(2026, 4, 1),
            blockedById: 'b1',
          );
          final blocker = createTestTask(
            id: 'b1',
            deadline: DateTime(2026, 5, 1),
          );
          when(() => mockRepo.getById('b1')).thenAnswer((_) async => blocker);

          final cmd = await TaskCrudService.buildCreateWithPropagationCommand(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );
          expect(cmd, isA<CompoundCommand>());
          final compound = cmd as CompoundCommand;
          expect(compound.commands.length, equals(2));
          expect(compound.commands[0], isA<CreateCommand<Task>>());
          expect(compound.commands[1], isA<UpdateCommand>());
        },
      );
    });

    group('buildUpdateWithPropagationCommand', () {
      test('returns single UpdateCommand without propagation', () async {
        final previous = createTestTask(id: 't1', title: 'Prev');
        final next = createTestTask(id: 't1', title: 'Next');
        final cmd = await TaskCrudService.buildUpdateWithPropagationCommand(
          repo: mockRepo,
          previous: previous,
          next: next,
          inheritParentDeadline: false,
        );
        expect(cmd, isA<UpdateCommand<Task>>());
        expect((cmd as UpdateCommand<Task>).next.title, equals('Next'));
      });

      test('returns CompoundCommand with propagation', () async {
        final previous = createTestTask(id: 't1');
        final next = createTestTask(
          id: 't1',
          deadline: DateTime(2026, 3, 1),
          blockedById: 'b1',
        );
        final blocker = createTestTask(
          id: 'b1',
          deadline: DateTime(2026, 6, 1),
        );
        when(() => mockRepo.getById('b1')).thenAnswer((_) async => blocker);

        final cmd = await TaskCrudService.buildUpdateWithPropagationCommand(
          repo: mockRepo,
          previous: previous,
          next: next,
          inheritParentDeadline: true,
        );
        expect(cmd, isA<CompoundCommand>());
        expect((cmd as CompoundCommand).commands.length, equals(2));
      });
    });

    group('buildDeleteCommand', () {
      test('returns single DeleteCommand when task has no subtasks', () async {
        final task = createTestTask(id: 't1', title: 'Task');
        when(() => mockRepo.getByParent('t1')).thenAnswer((_) async => []);
        final cmd = await TaskCrudService.buildDeleteCommand(
          repo: mockRepo,
          task: task,
          deleteSubtasks: true,
        );
        expect(cmd, isA<DeleteCommand<Task>>());
        expect((cmd as DeleteCommand<Task>).id, equals('t1'));
      });

      test(
        'returns CompoundCommand deleting subtasks and parent when deleteSubtasks is true',
        () async {
          final parent = createTestTask(id: 'p1', title: 'Parent');
          final sub = createTestTask(id: 's1', parentId: 'p1', title: 'Sub');
          when(() => mockRepo.getByParent('p1')).thenAnswer((_) async => [sub]);
          when(() => mockRepo.getByParent('s1')).thenAnswer((_) async => []);

          final cmd = await TaskCrudService.buildDeleteCommand(
            repo: mockRepo,
            task: parent,
            deleteSubtasks: true,
          );
          expect(cmd, isA<CompoundCommand>());
          final compound = cmd as CompoundCommand;
          expect(compound.commands.length, equals(2));
          expect(
            (compound.commands[0] as DeleteCommand<Task>).id,
            equals('s1'),
          );
          expect(
            (compound.commands[1] as DeleteCommand<Task>).id,
            equals('p1'),
          );
        },
      );

      test(
        'returns CompoundCommand unlinking subtasks and deleting parent when deleteSubtasks is false',
        () async {
          final parent = createTestTask(id: 'p1', title: 'Parent');
          final sub = createTestTask(id: 's1', parentId: 'p1', title: 'Sub');
          when(() => mockRepo.getByParent('p1')).thenAnswer((_) async => [sub]);
          when(() => mockRepo.getByParent('s1')).thenAnswer((_) async => []);

          final cmd = await TaskCrudService.buildDeleteCommand(
            repo: mockRepo,
            task: parent,
            deleteSubtasks: false,
          );
          expect(cmd, isA<CompoundCommand>());
          final compound = cmd as CompoundCommand;
          expect(compound.commands.length, equals(2));
          final subUpdate = compound.commands[0] as UpdateCommand<Task>;
          expect(subUpdate.next.id, equals('s1'));
          expect(subUpdate.next.parentId, isNull);
          expect(
            (compound.commands[1] as DeleteCommand<Task>).id,
            equals('p1'),
          );
        },
      );
    });
  });
}
