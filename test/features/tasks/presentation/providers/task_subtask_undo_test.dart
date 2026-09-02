import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('Subtask Auto-Completion Undo Integration', () {
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late MockLabelRepository mockLabelRepo;
    late MockHistoryRepository mockHistoryRepo;
    late MockSettingsRepository mockSettingsRepo;
    late ProviderContainer container;

    setUp(() {
      mockTaskRepo = MockTaskRepository();
      mockProjectRepo = MockProjectRepository();
      mockLabelRepo = MockLabelRepository();
      mockHistoryRepo = MockHistoryRepository();
      mockSettingsRepo = MockSettingsRepository();

      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          projectRepositoryProvider.overrideWithValue(mockProjectRepo),
          labelRepositoryProvider.overrideWithValue(mockLabelRepo),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'completing final subtask bundles parent auto-completion into CompoundCommand and reverts both on single undo',
      () async {
        final parent = Task(
          id: 'parent_1',
          title: 'Parent Task',
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
        );
        final subtask1 = Task(
          id: 'sub_1',
          title: 'Subtask 1',
          parentId: 'parent_1',
          status: TaskStatus.done,
          createdAt: DateTime.now(),
        );
        final subtask2 = Task(
          id: 'sub_2',
          title: 'Subtask 2',
          parentId: 'parent_1',
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
        );

        when(
          () => mockTaskRepo.getByParent('parent_1'),
        ).thenAnswer((_) async => [subtask1, subtask2]);
        when(
          () => mockTaskRepo.getById('parent_1'),
        ).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getById('sub_2'),
        ).thenAnswer((_) async => subtask2);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
        when(
          () => mockTaskRepo.getByDate(
            any(),
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
            prioritizeOverdue: any(named: 'prioritizeOverdue'),
          ),
        ).thenAnswer((_) async => []);
        when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
        when(
          () => mockTaskRepo.getUnscheduled(
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
            prioritizeOverdue: any(named: 'prioritizeOverdue'),
          ),
        ).thenAnswer((_) async => []);

        final taskNotifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await taskNotifier.completeTask(subtask2);

        // Verify both subtask2 and parent were updated to done
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'sub_2')
                  .having((t) => t.status, 'status', TaskStatus.done),
            ),
          ),
        ).called(1);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'parent_1')
                  .having((t) => t.status, 'status', TaskStatus.done),
            ),
          ),
        ).called(1);

        expect(undoRedo.state.canUndo, isTrue);
        expect(
          undoRedo.state.undoDescription,
          contains('auto-complete "Parent Task"'),
        );

        // Undoing once reverts BOTH parent and subtask
        await undoRedo.undo();
        await Future.delayed(Duration.zero);

        // Verify parent was restored to inProgress
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'parent_1')
                  .having((t) => t.status, 'status', TaskStatus.inProgress),
            ),
          ),
        ).called(1);

        // Verify subtask2 was restored to inProgress
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'sub_2')
                  .having((t) => t.status, 'status', TaskStatus.inProgress),
            ),
          ),
        ).called(1);
      },
    );
  });
}
