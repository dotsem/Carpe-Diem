import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_completion_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskCompletionService', () {
    late MockTaskRepository mockRepo;

    setUp(() {
      mockRepo = MockTaskRepository();
    });

    group('buildCompleteCommand', () {
      test(
        'sets status to done and completedAt when task has scheduledDate',
        () {
          final date = DateTime(2026, 7, 10);
          final task = createTestTask(
            id: 't1',
            title: 'Complete Task',
            scheduledDate: date,
            status: TaskStatus.inProgress,
          );

          final cmd = TaskCompletionService.buildCompleteCommand(
            repo: mockRepo,
            task: task,
          );

          expect(cmd, isA<UpdateCommand<Task>>());
          final updateCmd = cmd as UpdateCommand<Task>;
          expect(updateCmd.previous, equals(task));
          expect(updateCmd.next.status, equals(TaskStatus.done));
          expect(updateCmd.next.scheduledDate, equals(date.normalize));
          expect(updateCmd.next.completedAt, isNotNull);
          expect(updateCmd.displayName, equals('Complete Task'));
        },
      );

      test(
        'sets scheduledDate to today normalized when original date is null',
        () {
          final task = createTestTask(
            id: 't1',
            scheduledDate: null,
            status: TaskStatus.todo,
          );

          final cmd = TaskCompletionService.buildCompleteCommand(
            repo: mockRepo,
            task: task,
          );

          final updateCmd = cmd as UpdateCommand<Task>;
          expect(updateCmd.next.status, equals(TaskStatus.done));
          expect(
            updateCmd.next.scheduledDate,
            equals(DateTime.now().normalize),
          );
          expect(updateCmd.next.completedAt, isNotNull);
        },
      );
    });

    group('buildStartCommand', () {
      test('sets status to inProgress and preserves scheduledDate', () {
        final date = DateTime(2026, 8, 15);
        final task = createTestTask(
          id: 't1',
          title: 'Start Task',
          scheduledDate: date,
          status: TaskStatus.todo,
        );

        final cmd = TaskCompletionService.buildStartCommand(
          repo: mockRepo,
          task: task,
        );

        expect(cmd, isA<UpdateCommand<Task>>());
        final updateCmd = cmd as UpdateCommand<Task>;
        expect(updateCmd.next.status, equals(TaskStatus.inProgress));
        expect(updateCmd.next.scheduledDate, equals(date.normalize));
      });

      test(
        'sets scheduledDate to today normalized when original date is null',
        () {
          final task = createTestTask(id: 't1', scheduledDate: null);

          final cmd = TaskCompletionService.buildStartCommand(
            repo: mockRepo,
            task: task,
          );

          final updateCmd = cmd as UpdateCommand<Task>;
          expect(updateCmd.next.status, equals(TaskStatus.inProgress));
          expect(
            updateCmd.next.scheduledDate,
            equals(DateTime.now().normalize),
          );
        },
      );
    });

    group('buildStatusUpdateCommand', () {
      test(
        'updates status and retains existing sortOrder when newSortOrder is null',
        () {
          final task = createTestTask(
            id: 't1',
            status: TaskStatus.inProgress,
          ).copyWith(sortOrder: '0|i00005:');

          final cmd = TaskCompletionService.buildStatusUpdateCommand(
            repo: mockRepo,
            task: task,
            status: TaskStatus.todo,
          );

          final updateCmd = cmd as UpdateCommand<Task>;
          expect(updateCmd.next.status, equals(TaskStatus.todo));
          expect(updateCmd.next.sortOrder, equals('0|i00005:'));
        },
      );

      test(
        'updates status and modifies sortOrder when newSortOrder is provided',
        () {
          final task = createTestTask(
            id: 't1',
          ).copyWith(sortOrder: '0|i00001:');

          final cmd = TaskCompletionService.buildStatusUpdateCommand(
            repo: mockRepo,
            task: task,
            status: TaskStatus.done,
            newSortOrder: '0|i00010:',
          );

          final updateCmd = cmd as UpdateCommand<Task>;
          expect(updateCmd.next.status, equals(TaskStatus.done));
          expect(updateCmd.next.sortOrder, equals('0|i00010:'));
        },
      );
    });

    group('buildCompleteParentCascadeCommand', () {
      test(
        'builds compound command with updates for all incomplete subtasks and parent',
        () {
          final parent = createTestTask(
            id: 'p1',
            title: 'Parent Task',
            status: TaskStatus.inProgress,
          );
          final sub1 = createTestTask(
            id: 's1',
            title: 'Sub 1',
            parentId: 'p1',
            status: TaskStatus.todo,
          );
          final sub2 = createTestTask(
            id: 's2',
            title: 'Sub 2',
            parentId: 'p1',
            status: TaskStatus.inProgress,
            scheduledDate: DateTime(2026, 9, 1),
          );

          final conflict = SubtaskCompletionConflict(
            parentTask: parent,
            incompleteSubtasks: [sub1, sub2],
          );

          final compound =
              TaskCompletionService.buildCompleteParentCascadeCommand(
                repo: mockRepo,
                conflict: conflict,
              );

          expect(compound.commands.length, equals(3));
          expect(
            compound.description,
            equals('Complete "Parent Task" and 2 subtasks'),
          );

          final sub1Cmd = compound.commands[0] as UpdateCommand<Task>;
          final sub2Cmd = compound.commands[1] as UpdateCommand<Task>;
          final parentCmd = compound.commands[2] as UpdateCommand<Task>;

          expect(sub1Cmd.next.id, equals('s1'));
          expect(sub1Cmd.next.status, equals(TaskStatus.done));
          expect(sub1Cmd.next.completedAt, isNotNull);
          expect(sub1Cmd.next.scheduledDate, equals(DateTime.now().normalize));

          expect(sub2Cmd.next.id, equals('s2'));
          expect(sub2Cmd.next.status, equals(TaskStatus.done));
          expect(
            sub2Cmd.next.scheduledDate,
            equals(DateTime(2026, 9, 1).normalize),
          );

          expect(parentCmd.next.id, equals('p1'));
          expect(parentCmd.next.status, equals(TaskStatus.done));
          expect(parentCmd.next.completedAt, isNotNull);
        },
      );
    });
  });
}
