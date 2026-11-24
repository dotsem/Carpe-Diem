import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      Project(id: '', name: '', color: Colors.red, createdAt: DateTime.now()),
    );
  });

  group('projects', () {
    late MockProjectRepository mockRepo;
    late MockKeyValueRepository mockSettingsRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockProjectRepository();
      mockSettingsRepo = MockKeyValueRepository();
      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(mockRepo),
          keyValueRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'should initialize with empty state and load projects successfully',
      () async {
        final initial = container.read(projectProvider);
        expect(initial.projects, isEmpty);
        expect(initial.isLoading, isFalse);

        final dummyProject = Project(
          id: 'p1',
          name: 'Work Tasks',
          color: Colors.blue,
          createdAt: DateTime.now(),
        );

        when(() => mockRepo.getAll()).thenAnswer((_) async => [dummyProject]);

        await container.read(projectProvider.notifier).loadProjects();

        final updated = container.read(projectProvider);
        expect(updated.projects.length, equals(1));
        expect(updated.projects.first.id, equals('p1'));
        verify(() => mockRepo.getAll()).called(1);
      },
    );

    test('state lookup/copy and missing update are safe', () async {
      final project = Project(
        id: 'p1',
        name: 'Project',
        color: Colors.blue,
        createdAt: DateTime(2026),
      );
      final state = ProjectState(projects: [project]);
      expect(state.copyWith().projects, [project]);
      expect(state.getById('p1'), project);
      when(() => mockRepo.getById('p1')).thenAnswer((_) async => null);

      await container.read(projectProvider.notifier).updateProject(project);

      verifyNever(() => mockRepo.update(any()));
    });

    test('undoing a project creation refreshes projects', () async {
      when(() => mockRepo.insert(any())).thenAnswer((_) async {});
      when(() => mockRepo.delete(any())).thenAnswer((_) async {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);

      await container
          .read(projectProvider.notifier)
          .addProject(name: 'New', color: Colors.blue);
      await container.read(undoRedoProvider.notifier).undo();

      verify(() => mockRepo.getAll()).called(2);
    });

    test('should add project, call insert, and trigger reload', () async {
      when(() => mockRepo.insert(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);

      await container
          .read(projectProvider.notifier)
          .addProject(name: 'New App', color: Colors.red);

      verify(() => mockRepo.insert(any())).called(1);
      verify(() => mockRepo.getAll()).called(1);
    });

    test(
      'should toggle active state flag and call update repository',
      () async {
        final project = Project(
          id: 'p1',
          name: 'Archived',
          color: Colors.blue,
          createdAt: DateTime.now(),
        );

        when(() => mockRepo.update(any())).thenAnswer((_) async => {});
        when(() => mockRepo.getById('p1')).thenAnswer((_) async => project);
        when(() => mockRepo.getAll()).thenAnswer((_) async => [project]);

        await container
            .read(projectProvider.notifier)
            .toggleProjectActive(project);

        verify(
          () => mockRepo.update(
            any(
              that: isA<Project>().having(
                (p) => p.isActive,
                'isActive',
                isFalse,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'filteredProjectsProvider filters projects based on active filter',
      () async {
        final p1 = Project(
          id: 'p1',
          name: 'Urgent',
          color: Colors.red,
          isUrgent: true,
          createdAt: DateTime.now(),
        );
        final p2 = Project(
          id: 'p2',
          name: 'Normal',
          color: Colors.blue,
          createdAt: DateTime.now(),
        );

        when(() => mockRepo.getAll()).thenAnswer((_) async => [p1, p2]);
        await container.read(projectProvider.notifier).loadProjects();

        expect(container.read(filteredProjectsProvider).length, equals(2));

        container.read(filterProvider.notifier).setUrgentFilter(true);

        final filtered = container.read(filteredProjectsProvider);
        expect(filtered.length, equals(1));
        expect(filtered.first.id, equals('p1'));
      },
    );

    test(
      'activeFilteredProjectsProvider filters out inactive projects',
      () async {
        final active = Project(
          id: 'p1',
          name: 'Active',
          color: Colors.green,
          createdAt: DateTime.now(),
        );
        final inactive = Project(
          id: 'p2',
          name: 'Inactive',
          color: Colors.grey,
          isActive: false,
          createdAt: DateTime.now(),
        );

        when(
          () => mockRepo.getAll(),
        ).thenAnswer((_) async => [active, inactive]);
        await container.read(projectProvider.notifier).loadProjects();

        final result = container.read(activeFilteredProjectsProvider);
        expect(result.length, equals(1));
        expect(result.first.id, equals('p1'));
      },
    );

    test('reorders, finds, and resolves project labels', () async {
      final project = Project(
        id: 'p1',
        name: 'Project',
        color: Colors.blue,
        createdAt: DateTime(2026),
        sortOrder: 'a0',
        labelIds: const ['label', 'missing'],
      );
      const label = Label(id: 'label', name: 'Label', color: Colors.red);
      when(() => mockRepo.getAll()).thenAnswer((_) async => [project]);
      when(() => mockRepo.getById('p1')).thenAnswer((_) async => project);
      when(() => mockRepo.update(any())).thenAnswer((_) async {});
      await container.read(projectProvider.notifier).loadProjects();
      final notifier = container.read(projectProvider.notifier);

      await notifier.reorderProject(project, 'a1');

      expect(notifier.getById('p1'), project);
      expect(notifier.getById('missing'), isNull);
      expect(notifier.getLabels(project, const LabelState(labels: [label])), [
        label,
      ]);
      verify(
        () => mockRepo.update(
          any(
            that: isA<Project>().having((p) => p.sortOrder, 'sortOrder', 'a1'),
          ),
        ),
      ).called(1);

      await notifier.reorderProject(project, 'a0');
      verifyNever(() => mockRepo.update(any()));
    });

    test('reorder safely stops when the persisted project is gone', () async {
      final project = Project(
        id: 'gone',
        name: 'Gone',
        color: Colors.blue,
        createdAt: DateTime(2026),
      );
      when(() => mockRepo.getById('gone')).thenAnswer((_) async => null);

      await container
          .read(projectProvider.notifier)
          .reorderProject(project, 'a1');

      verifyNever(() => mockRepo.update(any()));
    });

    test('deletes a project and removes its active filter', () async {
      final project = Project(
        id: 'p1',
        name: 'Project',
        color: Colors.blue,
        createdAt: DateTime(2026),
      );
      when(() => mockRepo.delete('p1')).thenAnswer((_) async {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      container
          .read(filterProvider.notifier)
          .setFilter(const TaskFilter(projectIdsIncluded: {'p1'}));

      await container.read(projectProvider.notifier).deleteProject(project);

      verify(() => mockRepo.delete('p1')).called(1);
      expect(container.read(filterProvider).filter.projectIdsIncluded, isEmpty);
    });
  });
}
