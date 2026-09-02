import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
    registerFallbackValue(
      Project(id: '', name: '', color: Colors.blue, createdAt: DateTime.now()),
    );
    registerFallbackValue(const Label(id: '', name: '', color: Colors.blue));
  });

  group('UndoRedo Integration', () {
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

      // Default mock responses
      when(
        () => mockTaskRepo.getByDate(
          any(),
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        ),
      ).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getUnscheduled(
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        ),
      ).thenAnswer((_) async => []);
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'TaskNotifier should refresh UI list state on undo and redo of addTask',
      () async {
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

        final taskNotifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        // 1. Add task (executes CreateCommand)
        await taskNotifier.addTask(title: 'Integrated Task');
        verify(() => mockTaskRepo.insert(any())).called(1);

        // 2. Undo task creation
        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.delete(any())).called(1);
        verify(
          () => mockTaskRepo.getByDate(
            any(),
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
          ),
        ).called(greaterThan(0));

        // 3. Redo task creation
        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.insert(any())).called(1);
      },
    );

    test(
      'ProjectNotifier should refresh UI state on undo and redo of addProject',
      () async {
        when(() => mockProjectRepo.insert(any())).thenAnswer((_) async => {});
        when(() => mockProjectRepo.delete(any())).thenAnswer((_) async => {});

        final projectNotifier = container.read(projectProvider.notifier);

        // 1. Add project (executes CreateCommand)
        await projectNotifier.addProject(
          name: 'New Project',
          color: Colors.red,
        );
        verify(() => mockProjectRepo.insert(any())).called(1);

        // 2. Undo project creation
        await container.read(undoRedoProvider.notifier).undo();
        await Future.delayed(Duration.zero);
        verify(() => mockProjectRepo.delete(any())).called(1);
        verify(() => mockProjectRepo.getAll()).called(greaterThan(0));

        // 3. Redo project creation
        await container.read(undoRedoProvider.notifier).redo();
        await Future.delayed(Duration.zero);
        verify(() => mockProjectRepo.insert(any())).called(1);
      },
    );

    test(
      'LabelNotifier should refresh UI state on undo and redo of addLabel',
      () async {
        when(() => mockLabelRepo.insert(any())).thenAnswer((_) async => {});
        when(() => mockLabelRepo.delete(any())).thenAnswer((_) async => {});

        final labelNotifier = container.read(labelProvider.notifier);

        // 1. Add label (executes CreateCommand)
        await labelNotifier.addLabel(name: 'New Label', color: Colors.green);
        verify(() => mockLabelRepo.insert(any())).called(1);

        // 2. Undo label creation
        await container.read(undoRedoProvider.notifier).undo();
        await Future.delayed(Duration.zero);
        verify(() => mockLabelRepo.delete(any())).called(1);
        verify(() => mockLabelRepo.getAll()).called(greaterThan(0));

        // 3. Redo label creation
        await container.read(undoRedoProvider.notifier).redo();
        await Future.delayed(Duration.zero);
        verify(() => mockLabelRepo.insert(any())).called(1);
      },
    );

    test(
      'TaskNotifier reorderTask should register in undo/redo stack and revert on undo',
      () async {
        final task = Task(
          id: 't1',
          title: 'Task to Reorder',
          sortOrder: '0|i00000:',
          createdAt: DateTime.now(),
        );
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final taskNotifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await taskNotifier.reorderTask(task, '0|i00001:');
        verify(() => mockTaskRepo.update(any())).called(1);
        expect(undoRedo.state.canUndo, isTrue);
        expect(undoRedo.state.undoDescription, contains('Reorder task'));

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(1);
      },
    );

    test(
      'TaskNotifier bulkReorderTasks should register compound command in undo/redo stack',
      () async {
        final task1 = Task(
          id: 't1',
          title: 'Task 1',
          sortOrder: '0|i00000:',
          createdAt: DateTime.now(),
        );
        final task2 = Task(
          id: 't2',
          title: 'Task 2',
          sortOrder: '0|i00001:',
          createdAt: DateTime.now(),
        );

        when(() => mockTaskRepo.getById('t1')).thenAnswer((_) async => task1);
        when(() => mockTaskRepo.getById('t2')).thenAnswer((_) async => task2);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final taskNotifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await taskNotifier.bulkReorderTasks({
          't1': '0|i00002:',
          't2': '0|i00003:',
        });
        verify(() => mockTaskRepo.update(any())).called(2);
        expect(undoRedo.state.canUndo, isTrue);
        expect(undoRedo.state.undoDescription, equals('Reorder 2 tasks'));

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockTaskRepo.update(any())).called(2);
      },
    );

    test(
      'TaskNotifier deleteTask should cascade delete subtasks via CompoundCommand and restore on undo',
      () async {
        final parent = Task(
          id: 'parent_1',
          title: 'Parent Task',
          createdAt: DateTime.now(),
        );
        final subtask = Task(
          id: 'sub_1',
          title: 'Subtask 1',
          parentId: 'parent_1',
          createdAt: DateTime.now(),
        );

        when(
          () => mockTaskRepo.getUnscheduled(
            prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
          ),
        ).thenAnswer((_) async => [parent, subtask]);
        when(
          () => mockTaskRepo.getByParent('parent_1'),
        ).thenAnswer((_) async => [subtask]);
        when(
          () => mockTaskRepo.getByParent('sub_1'),
        ).thenAnswer((_) async => []);
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});

        final taskNotifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await taskNotifier.loadUnscheduledTasks();
        await taskNotifier.deleteTask(parent);

        verify(() => mockTaskRepo.delete('sub_1')).called(1);
        verify(() => mockTaskRepo.delete('parent_1')).called(1);
        expect(undoRedo.state.canUndo, isTrue);
        expect(
          undoRedo.state.undoDescription,
          contains('Delete "Parent Task" and 1 subtask'),
        );

        await undoRedo.undo();
        await Future.delayed(Duration.zero);

        verify(() => mockTaskRepo.insert(parent)).called(1);
        verify(() => mockTaskRepo.insert(subtask)).called(1);
      },
    );

    test(
      'TaskNotifier addTask with deadline propagation bundles into CompoundCommand and reverts all on undo',
      () async {
        final blocker = Task(
          id: 'blocker_1',
          title: 'Blocker Task',
          createdAt: DateTime.now(),
          deadline: DateTime(2026, 12, 31),
        );
        when(
          () => mockTaskRepo.getById('blocker_1'),
        ).thenAnswer((_) async => blocker);
        when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});
        when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

        final taskNotifier = container.read(taskProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await taskNotifier.addTask(
          title: 'Blocked Task',
          blockedById: 'blocker_1',
          deadline: DateTime(2026, 10, 1),
        );

        verify(() => mockTaskRepo.insert(any())).called(1);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'blocker_1')
                  .having((t) => t.deadline, 'deadline', DateTime(2026, 10, 1)),
            ),
          ),
        ).called(1);
        expect(undoRedo.state.canUndo, isTrue);
        expect(undoRedo.state.undoDescription, contains('propagated deadline'));

        await undoRedo.undo();
        await Future.delayed(Duration.zero);

        verify(() => mockTaskRepo.delete(any())).called(1);
        verify(
          () => mockTaskRepo.update(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', 'blocker_1')
                  .having(
                    (t) => t.deadline,
                    'deadline',
                    DateTime(2026, 12, 31),
                  ),
            ),
          ),
        ).called(1);
      },
    );
  });
}
