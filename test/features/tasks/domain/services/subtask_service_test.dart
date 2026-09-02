import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('SubtaskService', () {
    late MockTaskRepository mockRepo;

    setUp(() {
      mockRepo = MockTaskRepository();
    });

    group('checkSubtaskConflict', () {
      test('returns null when parent has no subtasks', () async {
        final parent = createTestTask(id: 'p1');
        when(() => mockRepo.getByParent('p1')).thenAnswer((_) async => []);

        final conflict = await SubtaskService.checkSubtaskConflict(
          repo: mockRepo,
          task: parent,
        );

        expect(conflict, isNull);
      });

      test('returns null when all subtasks are completed', () async {
        final parent = createTestTask(id: 'p1');
        final sub1 = createTestTask(
          id: 's1',
          parentId: 'p1',
          status: TaskStatus.done,
        );
        final sub2 = createTestTask(
          id: 's2',
          parentId: 'p1',
          status: TaskStatus.done,
        );
        when(
          () => mockRepo.getByParent('p1'),
        ).thenAnswer((_) async => [sub1, sub2]);

        final conflict = await SubtaskService.checkSubtaskConflict(
          repo: mockRepo,
          task: parent,
        );

        expect(conflict, isNull);
      });

      test('returns conflict with incomplete subtasks only', () async {
        final parent = createTestTask(id: 'p1');
        final sub1 = createTestTask(
          id: 's1',
          parentId: 'p1',
          status: TaskStatus.todo,
        );
        final sub2 = createTestTask(
          id: 's2',
          parentId: 'p1',
          status: TaskStatus.inProgress,
        );
        final sub3 = createTestTask(
          id: 's3',
          parentId: 'p1',
          status: TaskStatus.done,
        );
        when(
          () => mockRepo.getByParent('p1'),
        ).thenAnswer((_) async => [sub1, sub2, sub3]);

        final conflict = await SubtaskService.checkSubtaskConflict(
          repo: mockRepo,
          task: parent,
        );

        expect(conflict, isNotNull);
        expect(conflict!.parentTask, equals(parent));
        expect(conflict.incompleteSubtasks.length, equals(2));
        expect(
          conflict.incompleteSubtasks.map((s) => s.id),
          containsAll(['s1', 's2']),
        );
      });
    });

    group('buildCompleteSubtaskCommand', () {
      test('returns single UpdateCommand when task has no parentId', () async {
        final task = createTestTask(id: 't1', parentId: null);

        final cmd = await SubtaskService.buildCompleteSubtaskCommand(
          repo: mockRepo,
          task: task,
        );

        expect(cmd, isA<UpdateCommand<Task>>());
        final updateCmd = cmd as UpdateCommand<Task>;
        expect(updateCmd.next.status, equals(TaskStatus.done));
        expect(updateCmd.next.completedAt, isNotNull);
        verifyZeroInteractions(mockRepo);
      });

      test(
        'returns single UpdateCommand when siblings are still incomplete',
        () async {
          final subtask = createTestTask(
            id: 's1',
            parentId: 'p1',
            status: TaskStatus.inProgress,
          );
          final sibling = createTestTask(
            id: 's2',
            parentId: 'p1',
            status: TaskStatus.todo,
          );
          when(
            () => mockRepo.getByParent('p1'),
          ).thenAnswer((_) async => [subtask, sibling]);

          final cmd = await SubtaskService.buildCompleteSubtaskCommand(
            repo: mockRepo,
            task: subtask,
          );

          expect(cmd, isA<UpdateCommand<Task>>());
          final updateCmd = cmd as UpdateCommand<Task>;
          expect(updateCmd.next.id, equals('s1'));
          verifyNever(() => mockRepo.getById('p1'));
        },
      );

      test(
        'returns CompoundCommand auto-completing parent when all siblings done',
        () async {
          final parent = createTestTask(
            id: 'p1',
            title: 'Parent Task',
            status: TaskStatus.inProgress,
          );
          final subtask = createTestTask(
            id: 's1',
            title: 'Subtask 1',
            parentId: 'p1',
            status: TaskStatus.inProgress,
          );
          final sibling = createTestTask(
            id: 's2',
            parentId: 'p1',
            status: TaskStatus.done,
          );

          when(
            () => mockRepo.getByParent('p1'),
          ).thenAnswer((_) async => [subtask, sibling]);
          when(() => mockRepo.getById('p1')).thenAnswer((_) async => parent);

          final cmd = await SubtaskService.buildCompleteSubtaskCommand(
            repo: mockRepo,
            task: subtask,
          );

          expect(cmd, isA<CompoundCommand>());
          final compound = cmd as CompoundCommand;
          expect(compound.commands.length, equals(2));
          expect(compound.description, contains('auto-complete "Parent Task"'));

          final subCmd = compound.commands[0] as UpdateCommand<Task>;
          final parentCmd = compound.commands[1] as UpdateCommand<Task>;
          expect(subCmd.next.id, equals('s1'));
          expect(subCmd.next.status, equals(TaskStatus.done));
          expect(parentCmd.next.id, equals('p1'));
          expect(parentCmd.next.status, equals(TaskStatus.done));
        },
      );

      test(
        'returns single UpdateCommand when parent is already completed',
        () async {
          final parent = createTestTask(id: 'p1', status: TaskStatus.done);
          final subtask = createTestTask(
            id: 's1',
            parentId: 'p1',
            status: TaskStatus.inProgress,
          );
          when(
            () => mockRepo.getByParent('p1'),
          ).thenAnswer((_) async => [subtask]);
          when(() => mockRepo.getById('p1')).thenAnswer((_) async => parent);

          final cmd = await SubtaskService.buildCompleteSubtaskCommand(
            repo: mockRepo,
            task: subtask,
          );

          expect(cmd, isA<UpdateCommand<Task>>());
          expect((cmd as UpdateCommand<Task>).next.id, equals('s1'));
        },
      );

      test('returns single UpdateCommand when parent task is null', () async {
        final subtask = createTestTask(id: 's1', parentId: 'p_missing');
        when(
          () => mockRepo.getByParent('p_missing'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockRepo.getById('p_missing')).thenAnswer((_) async => null);

        final cmd = await SubtaskService.buildCompleteSubtaskCommand(
          repo: mockRepo,
          task: subtask,
        );

        expect(cmd, isA<UpdateCommand<Task>>());
      });
    });

    group('getAllSubtasks (in-memory)', () {
      test('returns empty list when no tasks match parentId', () {
        final tasks = [
          createTestTask(id: 't1'),
          createTestTask(id: 't2', parentId: 'other'),
        ];

        final result = SubtaskService.getAllSubtasks(
          parentId: 'p1',
          allTasks: tasks,
        );

        expect(result, isEmpty);
      });

      test('recursively gathers multi-level descendant subtasks', () {
        final root = createTestTask(id: 'root');
        final child1 = createTestTask(id: 'c1', parentId: 'root');
        final child2 = createTestTask(id: 'c2', parentId: 'root');
        final grandChild1 = createTestTask(id: 'gc1', parentId: 'c1');
        final greatGrandChild = createTestTask(id: 'ggc1', parentId: 'gc1');
        final other = createTestTask(id: 'other', parentId: 'someone_else');

        final all = [root, child1, child2, grandChild1, greatGrandChild, other];
        final result = SubtaskService.getAllSubtasks(
          parentId: 'root',
          allTasks: all,
        );

        expect(result.length, equals(4));
        expect(
          result.map((t) => t.id),
          containsAll(['c1', 'c2', 'gc1', 'ggc1']),
        );
        expect(result.map((t) => t.id), isNot(contains('other')));
      });
    });

    group('getAllSubtasksFromRepo (async)', () {
      test('recursively collects all subtasks from repository', () async {
        final child1 = createTestTask(id: 'c1', parentId: 'p1');
        final child2 = createTestTask(id: 'c2', parentId: 'p1');
        final grandChild = createTestTask(id: 'gc1', parentId: 'c1');

        when(
          () => mockRepo.getByParent('p1'),
        ).thenAnswer((_) async => [child1, child2]);
        when(
          () => mockRepo.getByParent('c1'),
        ).thenAnswer((_) async => [grandChild]);
        when(() => mockRepo.getByParent('c2')).thenAnswer((_) async => []);
        when(() => mockRepo.getByParent('gc1')).thenAnswer((_) async => []);

        final result = await SubtaskService.getAllSubtasksFromRepo(
          repo: mockRepo,
          parentId: 'p1',
        );

        expect(result.length, equals(3));
        expect(result.map((t) => t.id), containsAll(['c1', 'c2', 'gc1']));
      });
    });
  });
}
