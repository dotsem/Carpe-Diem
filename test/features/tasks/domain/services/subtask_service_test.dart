import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('SubtaskService', () {
    late MockTaskRepository mockRepo;
    late SubtaskService service;

    setUp(() {
      mockRepo = MockTaskRepository();
      service = SubtaskService(mockRepo);
    });

    group('checkSubtaskConflict', () {
      test('returns null when parent has no subtasks', () async {
        final parent = createTestTask(id: 'p1');
        when(() => mockRepo.getByParent('p1')).thenAnswer((_) async => []);

        final conflict = await service.checkSubtaskConflict(parent);

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

        final conflict = await service.checkSubtaskConflict(parent);

        expect(conflict, isNull);
      });

      test('returns conflict with incomplete subtasks only', () async {
        final parent = createTestTask(id: 'p1');
        final sub1 = createTestTask(id: 's1', parentId: 'p1');
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

        final conflict = await service.checkSubtaskConflict(parent);

        expect(conflict, isNotNull);
        expect(conflict!.parentTask, equals(parent));
        expect(conflict.incompleteSubtasks.length, equals(2));
        expect(
          conflict.incompleteSubtasks.map((s) => s.id),
          containsAll(['s1', 's2']),
        );
      });
    });

    group('findCompletableParent', () {
      test('returns null when task has no parentId', () async {
        final task = createTestTask();

        final parent = await service.findCompletableParent(task);

        expect(parent, isNull);
        verifyZeroInteractions(mockRepo);
      });

      test('returns null when siblings are still incomplete', () async {
        final subtask = createTestTask(id: 's1', parentId: 'p1');
        final sibling = createTestTask(id: 's2', parentId: 'p1');
        when(
          () => mockRepo.getByParent('p1'),
        ).thenAnswer((_) async => [subtask, sibling]);

        final parent = await service.findCompletableParent(subtask);

        expect(parent, isNull);
        verifyNever(() => mockRepo.getById('p1'));
      });

      test('returns parent when all other siblings are done', () async {
        final parentTask = createTestTask(id: 'p1');
        final subtask = createTestTask(
          id: 's1',
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
        when(() => mockRepo.getById('p1')).thenAnswer((_) async => parentTask);

        final parent = await service.findCompletableParent(subtask);

        expect(parent?.id, equals('p1'));
      });

      test('returns null when parent is already completed', () async {
        final parentTask = createTestTask(id: 'p1', status: TaskStatus.done);
        final subtask = createTestTask(id: 's1', parentId: 'p1');
        when(
          () => mockRepo.getByParent('p1'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockRepo.getById('p1')).thenAnswer((_) async => parentTask);

        final parent = await service.findCompletableParent(subtask);

        expect(parent, isNull);
      });

      test('returns null when parent is missing', () async {
        final subtask = createTestTask(id: 's1', parentId: 'p_missing');
        when(
          () => mockRepo.getByParent('p_missing'),
        ).thenAnswer((_) async => [subtask]);
        when(() => mockRepo.getById('p_missing')).thenAnswer((_) async => null);

        final parent = await service.findCompletableParent(subtask);

        expect(parent, isNull);
      });
    });

    group('getAllSubtasks (in-memory)', () {
      test('returns empty list when no tasks match parentId', () {
        final tasks = [
          createTestTask(),
          createTestTask(id: 't2', parentId: 'other'),
        ];

        final result = service.getAllSubtasks(parentId: 'p1', allTasks: tasks);

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
        final result = service.getAllSubtasks(parentId: 'root', allTasks: all);

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

        final result = await service.getAllSubtasksFromRepo('p1');

        expect(result.length, equals(3));
        expect(result.map((t) => t.id), containsAll(['c1', 'c2', 'gc1']));
      });
    });
  });
}
