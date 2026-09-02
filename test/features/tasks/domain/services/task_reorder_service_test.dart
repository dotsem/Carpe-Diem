import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('TaskReorderService', () {
    late MockTaskRepository mockRepo;
    const defaultSettings = SettingsState({});

    setUp(() {
      mockRepo = MockTaskRepository();
    });

    group('computeSortOrder', () {
      test('returns default rank when activeList is empty', () {
        final rank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.bottom,
          activeList: [],
        );
        expect(rank, equals(LexoRankUtils.defaultRank));
      });

      test('computes top rank on non-empty list', () {
        final t1 = createTestTask(id: 't1').copyWith(sortOrder: 'a5');
        final rank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.top,
          activeList: [t1],
        );
        expect(rank.compareTo(t1.sortOrder), lessThan(0));
      });

      test('computes middle rank for single item list', () {
        final t1 = createTestTask(id: 't1').copyWith(sortOrder: 'a5');
        final rank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.middle,
          activeList: [t1],
        );
        expect(rank.compareTo(t1.sortOrder), lessThan(0));
      });

      test('computes middle rank for multiple items list', () {
        final t1 = createTestTask(id: 't1').copyWith(sortOrder: 'a1');
        final t2 = createTestTask(id: 't2').copyWith(sortOrder: 'a9');
        final rank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.middle,
          activeList: [t1, t2],
        );
        expect(rank.compareTo(t1.sortOrder), greaterThan(0));
        expect(rank.compareTo(t2.sortOrder), lessThan(0));
      });

      test('computes bottom rank on non-empty list', () {
        final t1 = createTestTask(id: 't1').copyWith(sortOrder: 'a5');
        final rank = TaskReorderService.computeSortOrder(
          placement: TaskPlacement.bottom,
          activeList: [t1],
        );
        expect(rank.compareTo(t1.sortOrder), greaterThan(0));
      });
    });

    group('optimisticallyReorder', () {
      test('returns currentList untouched when task is not present', () {
        final list = [createTestTask(id: 't1')];
        final notInList = createTestTask(id: 't2');
        final result = TaskReorderService.optimisticallyReorder(
          currentList: list,
          updatedTask: notInList,
          prioritizeOverdue: true,
          prioritizeDeadlines: true,
        );
        expect(result, equals(list));
      });

      test('sorts urgent tasks to the front', () {
        final normal = createTestTask(id: 't1', isUrgent: false);
        final urgent = createTestTask(id: 't2', isUrgent: false);
        final updatedUrgent = urgent.copyWith(isUrgent: true);
        final result = TaskReorderService.optimisticallyReorder(
          currentList: [normal, urgent],
          updatedTask: updatedUrgent,
          prioritizeOverdue: false,
          prioritizeDeadlines: false,
        );

        expect(result.first.id, equals('t2'));
      });

      test('respects sortOrder string lexicographical order', () {
        final t1 = createTestTask(id: 't1').copyWith(sortOrder: '0|i00005:');
        final t2 = createTestTask(id: 't2').copyWith(sortOrder: '0|i00010:');
        final updatedT2 = t2.copyWith(sortOrder: '0|i00001:');
        final result = TaskReorderService.optimisticallyReorder(
          currentList: [t1, t2],
          updatedTask: updatedT2,
          prioritizeOverdue: false,
          prioritizeDeadlines: false,
        );

        expect(result.map((t) => t.id), equals(['t2', 't1']));
      });
    });

    group('applyOptimisticTask and applyBulkOptimisticReorder', () {
      test('updates matching task in TaskState collections', () {
        final t1 = createTestTask(id: 't1').copyWith(sortOrder: '0|i00010:');
        final state = TaskState(
          currentDate: DateTime(2026, 1, 1),
          tasks: [t1],
          overdueTasks: [t1],
          unscheduledTasks: [t1],
        );
        final updatedT1 = t1.copyWith(sortOrder: '0|i00001:');
        final newState = TaskReorderService.applyOptimisticTask(
          state: state,
          task: updatedT1,
          settings: defaultSettings,
        );

        expect(newState.tasks.first.sortOrder, equals('0|i00001:'));
        expect(newState.overdueTasks.first.sortOrder, equals('0|i00001:'));
        expect(newState.unscheduledTasks.first.sortOrder, equals('0|i00001:'));
      });

      test('applies bulk optimistic reorders across state collections', () {
        final t1 = createTestTask(id: 't1').copyWith(sortOrder: '0|i00010:');
        final t2 = createTestTask(id: 't2').copyWith(sortOrder: '0|i00020:');
        final state = TaskState(
          currentDate: DateTime(2026, 1, 1),
          tasks: [t1, t2],
        );

        final newState = TaskReorderService.applyBulkOptimisticReorder(
          state: state,
          updates: {'t1': '0|i00030:'},
          settings: defaultSettings,
        );

        expect(newState.tasks.map((t) => t.id), equals(['t2', 't1']));
      });
    });

    group('buildReorderCommand and buildBulkReorderCommand', () {
      test(
        'buildReorderCommand creates UpdateCommand with custom description',
        () {
          final prev = createTestTask(id: 't1', title: 'Task 1');
          final next = prev.copyWith(sortOrder: '0|i00050:');
          final cmd = TaskReorderService.buildReorderCommand(
            repo: mockRepo,
            previous: prev,
            next: next,
          );

          expect(cmd, isA<UpdateCommand<Task>>());
          expect(cmd.description, contains('Reorder task: "Task 1"'));
        },
      );

      test(
        'buildBulkReorderCommand handles empty and missing updates',
        () async {
          final cmdEmpty = await TaskReorderService.buildBulkReorderCommand(
            repo: mockRepo,
            updates: {},
          );
          expect(cmdEmpty, isNull);

          when(() => mockRepo.getById('missing')).thenAnswer((_) async => null);
          final cmdMissing = await TaskReorderService.buildBulkReorderCommand(
            repo: mockRepo,
            updates: {'missing': '0|i00010:'},
          );
          expect(cmdMissing, isNull);
        },
      );

      test(
        'buildBulkReorderCommand returns single UpdateCommand for 1 item',
        () async {
          final t1 = createTestTask(id: 't1', title: 'T1');
          when(() => mockRepo.getById('t1')).thenAnswer((_) async => t1);

          final cmd = await TaskReorderService.buildBulkReorderCommand(
            repo: mockRepo,
            updates: {'t1': '0|i00010:'},
          );
          expect(cmd, isA<UpdateCommand<Task>>());
        },
      );

      test(
        'buildBulkReorderCommand returns CompoundCommand for multiple items',
        () async {
          final t1 = createTestTask(id: 't1', title: 'T1');
          final t2 = createTestTask(id: 't2', title: 'T2');
          when(() => mockRepo.getById('t1')).thenAnswer((_) async => t1);
          when(() => mockRepo.getById('t2')).thenAnswer((_) async => t2);

          final cmd = await TaskReorderService.buildBulkReorderCommand(
            repo: mockRepo,
            updates: {'t1': '0|i00010:', 't2': '0|i00020:'},
          );
          expect(cmd, isA<CompoundCommand>());
          expect((cmd as CompoundCommand).commands.length, equals(2));
        },
      );
    });

    group('getRelevantTasksList', () {
      test(
        'queries appropriate repository methods based on parameters',
        () async {
          when(() => mockRepo.getByParent('p1')).thenAnswer((_) async => []);
          await TaskReorderService.getRelevantTasksList(
            repo: mockRepo,
            parentId: 'p1',
            projectId: 'proj1',
            scheduledDate: DateTime.now(),
            prioritizeDeadlines: false,
            prioritizeOverdue: false,
          );
          verify(() => mockRepo.getByParent('p1')).called(1);

          when(
            () => mockRepo.getByProjectUnscheduled(
              'proj1',
              prioritizeDeadlines: true,
              prioritizeOverdue: true,
            ),
          ).thenAnswer((_) async => []);
          await TaskReorderService.getRelevantTasksList(
            repo: mockRepo,
            parentId: null,
            projectId: 'proj1',
            scheduledDate: null,
            prioritizeDeadlines: true,
            prioritizeOverdue: true,
          );
          verify(
            () => mockRepo.getByProjectUnscheduled(
              'proj1',
              prioritizeDeadlines: true,
              prioritizeOverdue: true,
            ),
          ).called(1);

          when(
            () => mockRepo.getUnscheduled(
              prioritizeDeadlines: false,
              prioritizeOverdue: false,
            ),
          ).thenAnswer((_) async => []);
          await TaskReorderService.getRelevantTasksList(
            repo: mockRepo,
            parentId: null,
            projectId: null,
            scheduledDate: null,
            prioritizeDeadlines: false,
            prioritizeOverdue: false,
          );
          verify(
            () => mockRepo.getUnscheduled(
              prioritizeDeadlines: false,
              prioritizeOverdue: false,
            ),
          ).called(1);
        },
      );
    });
  });
}
