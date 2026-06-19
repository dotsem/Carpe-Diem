import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Project(
      id: '',
      name: '',
      color: Colors.red,
      createdAt: DateTime.now(),
    ));
  });

  group('projects', () {
    late MockProjectRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockProjectRepository();
      container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty state and load projects successfully', () async {
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
    });

    test('should add project, call insert, and trigger reload', () async {
      when(() => mockRepo.insert(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);

      await container.read(projectProvider.notifier).addProject(
        name: 'New App',
        color: Colors.red,
      );

      verify(() => mockRepo.insert(any())).called(1);
      verify(() => mockRepo.getAll()).called(1);
    });

    test('should toggle active state flag and call update repository', () async {
      final project = Project(
        id: 'p1',
        name: 'Archived',
        color: Colors.blue,
        isActive: true,
        createdAt: DateTime.now(),
      );

      when(() => mockRepo.update(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getById('p1')).thenAnswer((_) async => project);
      when(() => mockRepo.getAll()).thenAnswer((_) async => [project]);

      await container.read(projectProvider.notifier).toggleProjectActive(project);

      verify(() => mockRepo.update(any(that: isA<Project>().having((p) => p.isActive, 'isActive', isFalse)))).called(1);
    });
  });
}
