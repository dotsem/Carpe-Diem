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

  group('UndoRedo Cross-Feature Integration', () {
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
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);

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

    test('TaskNotifier refreshes state on undo and redo of addTask', () async {
      when(() => mockTaskRepo.insert(any())).thenAnswer((_) async => {});
      when(() => mockTaskRepo.delete(any())).thenAnswer((_) async => {});

      final taskNotifier = container.read(taskProvider.notifier);
      final undoRedo = container.read(undoRedoProvider.notifier);

      await taskNotifier.addTask(title: 'Integrated Task');
      verify(() => mockTaskRepo.insert(any())).called(1);

      await undoRedo.undo();
      await Future.delayed(Duration.zero);
      verify(() => mockTaskRepo.delete(any())).called(1);

      await undoRedo.redo();
      await Future.delayed(Duration.zero);
      verify(() => mockTaskRepo.insert(any())).called(1);
    });

    test(
      'ProjectNotifier refreshes state on undo and redo of addProject',
      () async {
        when(() => mockProjectRepo.insert(any())).thenAnswer((_) async => {});
        when(() => mockProjectRepo.delete(any())).thenAnswer((_) async => {});

        final projectNotifier = container.read(projectProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await projectNotifier.addProject(
          name: 'New Project',
          color: Colors.red,
        );
        verify(() => mockProjectRepo.insert(any())).called(1);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockProjectRepo.delete(any())).called(1);
        verify(() => mockProjectRepo.getAll()).called(greaterThan(0));

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockProjectRepo.insert(any())).called(1);
      },
    );

    test(
      'LabelNotifier refreshes state on undo and redo of addLabel',
      () async {
        when(() => mockLabelRepo.insert(any())).thenAnswer((_) async => {});
        when(() => mockLabelRepo.delete(any())).thenAnswer((_) async => {});

        final labelNotifier = container.read(labelProvider.notifier);
        final undoRedo = container.read(undoRedoProvider.notifier);

        await labelNotifier.addLabel(name: 'New Label', color: Colors.green);
        verify(() => mockLabelRepo.insert(any())).called(1);

        await undoRedo.undo();
        await Future.delayed(Duration.zero);
        verify(() => mockLabelRepo.delete(any())).called(1);
        verify(() => mockLabelRepo.getAll()).called(greaterThan(0));

        await undoRedo.redo();
        await Future.delayed(Duration.zero);
        verify(() => mockLabelRepo.insert(any())).called(1);
      },
    );
  });
}
