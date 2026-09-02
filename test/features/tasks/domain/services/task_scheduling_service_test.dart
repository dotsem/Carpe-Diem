import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_scheduling_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('TaskSchedulingService', () {
    late MockTaskRepository mockRepo;

    setUp(() {
      mockRepo = MockTaskRepository();
    });

    group('autoScheduleDeadlines', () {
      test(
        'schedules unscheduled tasks when deadline is today or earlier',
        () async {
          final today = DateTime(2026, 8, 10);
          final overdueDeadline = DateTime(2026, 8, 5);
          final futureDeadline = DateTime(2026, 8, 20);

          final task1 = createTestTask(id: 't1', deadline: overdueDeadline);
          final task2 = createTestTask(id: 't2', deadline: futureDeadline);
          final task3 = createTestTask(id: 't3', deadline: null);

          when(
            () => mockRepo.getUnscheduled(),
          ).thenAnswer((_) async => [task1, task2, task3]);
          when(() => mockRepo.update(any())).thenAnswer((_) async => {});

          await TaskSchedulingService.autoScheduleDeadlines(
            repo: mockRepo,
            today: today,
          );

          verify(
            () => mockRepo.update(
              any(
                that: isA<Task>()
                    .having((t) => t.id, 'id', 't1')
                    .having(
                      (t) => t.scheduledDate,
                      'scheduledDate',
                      overdueDeadline.normalize,
                    ),
              ),
            ),
          ).called(1);
          verifyNever(
            () => mockRepo.update(
              any(that: isA<Task>().having((t) => t.id, 'id', 't2')),
            ),
          );
          verifyNever(
            () => mockRepo.update(
              any(that: isA<Task>().having((t) => t.id, 'id', 't3')),
            ),
          );
        },
      );
    });

    group('buildScheduleCascadeCommand', () {
      test('returns single UpdateCommand when cascadeChildren is false', () {
        final task = createTestTask(id: 'p1', title: 'Parent');
        final subtask = createTestTask(id: 's1', parentId: 'p1');

        final cmd = TaskSchedulingService.buildScheduleCascadeCommand(
          repo: mockRepo,
          task: task,
          date: DateTime(2026, 9, 1),
          cascadeChildren: false,
          subtasks: [subtask],
        );

        expect(cmd, isA<UpdateCommand<Task>>());
        expect((cmd as UpdateCommand<Task>).next.id, equals('p1'));
      });

      test(
        'returns CompoundCommand when cascadeChildren is true with incomplete subtasks',
        () {
          final task = createTestTask(id: 'p1', title: 'Parent Task');
          final sub1 = createTestTask(
            id: 's1',
            parentId: 'p1',
            status: TaskStatus.todo,
          );
          final sub2 = createTestTask(
            id: 's2',
            parentId: 'p1',
            status: TaskStatus.done,
          );

          final cmd = TaskSchedulingService.buildScheduleCascadeCommand(
            repo: mockRepo,
            task: task,
            date: DateTime(2026, 9, 1),
            cascadeChildren: true,
            subtasks: [sub1, sub2],
          );

          expect(cmd, isA<CompoundCommand>());
          final compound = cmd as CompoundCommand;
          expect(compound.commands.length, equals(2));
          expect(
            compound.description,
            contains('Schedule "Parent Task" and 1 subtask'),
          );
        },
      );
    });

    group('buildUnscheduleCascadeCommand', () {
      test('returns single UpdateCommand when unscheduleChildren is false', () {
        final task = createTestTask(
          id: 'p1',
          scheduledDate: DateTime(2026, 8, 1),
          status: TaskStatus.inProgress,
        );

        final cmd = TaskSchedulingService.buildUnscheduleCascadeCommand(
          repo: mockRepo,
          task: task,
          resetStatus: true,
          unscheduleChildren: false,
          subtasks: [],
        );

        expect(cmd, isA<UpdateCommand<Task>>());
        final updateCmd = cmd as UpdateCommand<Task>;
        expect(updateCmd.next.scheduledDate, isNull);
        expect(updateCmd.next.status, equals(TaskStatus.todo));
      });

      test(
        'returns CompoundCommand unscheduling parent and scheduled subtasks',
        () {
          final parent = createTestTask(
            id: 'p1',
            title: 'Parent',
            scheduledDate: DateTime(2026, 8, 1),
          );
          final sub1 = createTestTask(
            id: 's1',
            parentId: 'p1',
            scheduledDate: DateTime(2026, 8, 1),
          );
          final sub2 = createTestTask(
            id: 's2',
            parentId: 'p1',
            scheduledDate: null,
          );

          final cmd = TaskSchedulingService.buildUnscheduleCascadeCommand(
            repo: mockRepo,
            task: parent,
            resetStatus: false,
            unscheduleChildren: true,
            subtasks: [sub1, sub2],
          );

          expect(cmd, isA<CompoundCommand>());
          final compound = cmd as CompoundCommand;
          expect(compound.commands.length, equals(2));
          expect(
            compound.description,
            contains('Unschedule "Parent" and 1 subtask'),
          );
        },
      );
    });

    group('buildBulkScheduleCommand', () {
      test('returns null when taskIds is empty', () async {
        final cmd = await TaskSchedulingService.buildBulkScheduleCommand(
          repo: mockRepo,
          taskIds: [],
          date: DateTime(2026, 8, 1),
          getTaskById: (id) async => null,
        );
        expect(cmd, isNull);
      });

      test(
        'schedules tasks and auto-schedules unscheduled incomplete subtasks',
        () async {
          final parent = createTestTask(id: 'p1', title: 'Parent');
          final sub1 = createTestTask(
            id: 's1',
            parentId: 'p1',
            scheduledDate: null,
            status: TaskStatus.todo,
          );

          when(
            () => mockRepo.getByParent('p1'),
          ).thenAnswer((_) async => [sub1]);

          final cmd = await TaskSchedulingService.buildBulkScheduleCommand(
            repo: mockRepo,
            taskIds: ['p1'],
            date: DateTime(2026, 8, 1),
            getTaskById: (id) async => id == 'p1' ? parent : null,
          );

          expect(cmd, isA<CompoundCommand>());
          final compound = cmd as CompoundCommand;
          expect(compound.commands.length, equals(2));
        },
      );
    });

    group('pickRandomTask', () {
      test('returns null when task list is empty', () {
        expect(TaskSchedulingService.pickRandomTask([]), isNull);
      });

      test('returns null when all tasks are blocked or completed', () {
        final blocked = createTestTask(id: 't1', blockedById: 'blocker');
        final done = createTestTask(id: 't2', status: TaskStatus.done);

        final task = TaskSchedulingService.pickRandomTask([blocked, done]);
        expect(task, isNull);
      });

      test('picks unblocked and incomplete task', () {
        final blocked = createTestTask(id: 't1', blockedById: 'blocker');
        final unblocked = createTestTask(id: 't2', status: TaskStatus.todo);

        final task = TaskSchedulingService.pickRandomTask([blocked, unblocked]);
        expect(task, isNotNull);
        expect(task!.id, equals('t2'));
      });
    });
  });
}
