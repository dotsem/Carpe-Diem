import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('DeadlinePropagationService', () {
    late MockTaskRepository mockRepo;

    setUp(() {
      mockRepo = MockTaskRepository();
    });

    test('returns empty list when inheritParentDeadline is false', () async {
      final task = createTestTask(
        id: 't1',
        deadline: DateTime(2026, 5, 1),
        blockedById: 'b1',
      );

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: false,
          );

      expect(commands, isEmpty);
      verifyZeroInteractions(mockRepo);
    });

    test('returns empty list when task deadline is null', () async {
      final task = createTestTask(id: 't1', deadline: null, blockedById: 'b1');

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands, isEmpty);
      verifyZeroInteractions(mockRepo);
    });

    test('returns empty list when blockedById is null', () async {
      final task = createTestTask(
        id: 't1',
        deadline: DateTime(2026, 5, 1),
        blockedById: null,
      );

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands, isEmpty);
      verifyZeroInteractions(mockRepo);
    });

    test('returns empty list when blocker is not found in repo', () async {
      final task = createTestTask(
        id: 't1',
        deadline: DateTime(2026, 5, 1),
        blockedById: 'nonexistent',
      );
      when(() => mockRepo.getById('nonexistent')).thenAnswer((_) async => null);

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands, isEmpty);
      verify(() => mockRepo.getById('nonexistent')).called(1);
    });

    test('returns empty list when blocker has earlier deadline', () async {
      final task = createTestTask(
        id: 't1',
        deadline: DateTime(2026, 5, 10),
        blockedById: 'b1',
      );
      final blocker = createTestTask(id: 'b1', deadline: DateTime(2026, 5, 5));
      when(() => mockRepo.getById('b1')).thenAnswer((_) async => blocker);

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands, isEmpty);
    });

    test('returns empty list when blocker has exact same deadline', () async {
      final deadline = DateTime(2026, 5, 10);
      final task = createTestTask(
        id: 't1',
        deadline: deadline,
        blockedById: 'b1',
      );
      final blocker = createTestTask(id: 'b1', deadline: deadline);
      when(() => mockRepo.getById('b1')).thenAnswer((_) async => blocker);

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands, isEmpty);
    });

    test('updates blocker when blocker deadline is later', () async {
      final task = createTestTask(
        id: 't1',
        deadline: DateTime(2026, 5, 1),
        blockedById: 'b1',
      );
      final blocker = createTestTask(
        id: 'b1',
        title: 'Blocker Task',
        deadline: DateTime(2026, 5, 15),
      );
      when(() => mockRepo.getById('b1')).thenAnswer((_) async => blocker);

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands.length, equals(1));
      expect(commands.first.previous, equals(blocker));
      expect(commands.first.next.deadline, equals(DateTime(2026, 5, 1)));
      expect(commands.first.displayName, equals('Blocker Task'));
    });

    test('updates blocker when blocker deadline is null', () async {
      final task = createTestTask(
        id: 't1',
        deadline: DateTime(2026, 5, 1),
        blockedById: 'b1',
      );
      final blocker = createTestTask(id: 'b1', deadline: null);
      when(() => mockRepo.getById('b1')).thenAnswer((_) async => blocker);

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands.length, equals(1));
      expect(commands.first.next.deadline, equals(DateTime(2026, 5, 1)));
    });

    test('propagates deadline up multi-level blocker chain', () async {
      final task = createTestTask(
        id: 't1',
        deadline: DateTime(2026, 3, 1),
        blockedById: 'b1',
      );
      final blocker1 = createTestTask(
        id: 'b1',
        deadline: DateTime(2026, 3, 10),
        blockedById: 'b2',
      );
      final blocker2 = createTestTask(
        id: 'b2',
        deadline: DateTime(2026, 3, 20),
      );

      when(() => mockRepo.getById('b1')).thenAnswer((_) async => blocker1);
      when(() => mockRepo.getById('b2')).thenAnswer((_) async => blocker2);

      final commands =
          await DeadlinePropagationService.buildPropagationCommands(
            repo: mockRepo,
            task: task,
            inheritParentDeadline: true,
          );

      expect(commands.length, equals(2));
      expect(commands[0].next.id, equals('b1'));
      expect(commands[0].next.deadline, equals(DateTime(2026, 3, 1)));
      expect(commands[1].next.id, equals('b2'));
      expect(commands[1].next.deadline, equals(DateTime(2026, 3, 1)));
    });

    test(
      'prevents infinite recursion on cyclic blocker dependencies',
      () async {
        final taskA = createTestTask(
          id: 'a',
          deadline: DateTime(2026, 4, 1),
          blockedById: 'b',
        );
        final taskB = createTestTask(
          id: 'b',
          deadline: DateTime(2026, 4, 10),
          blockedById: 'a',
        );

        when(() => mockRepo.getById('b')).thenAnswer((_) async => taskB);
        when(() => mockRepo.getById('a')).thenAnswer((_) async => taskA);

        final commands =
            await DeadlinePropagationService.buildPropagationCommands(
              repo: mockRepo,
              task: taskA,
              inheritParentDeadline: true,
            );

        expect(commands.length, equals(1));
        expect(commands.first.next.id, equals('b'));
      },
    );
  });
}
