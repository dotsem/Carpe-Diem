import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/hidden_counts_provider.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  group('filter', () {
    late MockKeyValueRepository mockSettingsRepo;
    late MockProjectRepository mockProjectRepo;
    late MockTaskRepository mockTaskRepo;
    late MockHistoryRepository mockHistoryRepo;
    late ProviderContainer container;

    setUp(() {
      mockSettingsRepo = MockKeyValueRepository();
      mockProjectRepo = MockProjectRepository();
      mockTaskRepo = MockTaskRepository();
      mockHistoryRepo = MockHistoryRepository();

      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getAll()).thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockSettingsRepo),
          projectRepositoryProvider.overrideWithValue(mockProjectRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('returns 0 hidden projects when filter is empty', () {
      final result = container.read(hiddenProjectsCountProvider);
      expect(result.hasHidden, false);
      expect(result.activeHidden, 0);
      expect(result.archivedHidden, 0);
    });

    test('calculates hidden active and archived projects correctly', () async {
      final now = DateTime.now();
      final p1 = Project(
        id: 'p1',
        name: 'Urgent Project',
        color: const Color(0xFF0000FF),
        createdAt: now,
        isUrgent: true,
        isActive: true,
      );
      final p2 = Project(
        id: 'p2',
        name: 'Normal Active Project',
        color: const Color(0xFF0000FF),
        createdAt: now,
        isUrgent: false,
        isActive: true,
      );
      final p3 = Project(
        id: 'p3',
        name: 'Normal Archived Project',
        color: const Color(0xFF0000FF),
        createdAt: now,
        isUrgent: false,
        isActive: false,
      );

      when(
        () => mockProjectRepo.getAll(),
      ).thenAnswer((_) async => [p1, p2, p3]);

      await container.read(projectProvider.notifier).loadProjects();

      container
          .read(filterProvider.notifier)
          .setFilter(const TaskFilter(isUrgent: true));

      final result = container.read(hiddenProjectsCountProvider);
      expect(result.hasHidden, true);
      expect(result.activeHidden, 1);
      expect(result.archivedHidden, 1);
      expect(result.totalHidden, 2);
    });

    test('returns 0 hidden counts when filters are bypassed', () async {
      final now = DateTime.now();
      final p1 = Project(
        id: 'p1',
        name: 'Urgent Project',
        color: const Color(0xFF0000FF),
        createdAt: now,
        isUrgent: true,
        isActive: true,
      );
      final p2 = Project(
        id: 'p2',
        name: 'Normal Active Project',
        color: const Color(0xFF0000FF),
        createdAt: now,
        isUrgent: false,
        isActive: true,
      );

      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => [p1, p2]);
      await container.read(projectProvider.notifier).loadProjects();

      final filterNotifier = container.read(filterProvider.notifier);
      filterNotifier.setFilter(const TaskFilter(isUrgent: true));
      filterNotifier.toggleBypass();

      final result = container.read(hiddenProjectsCountProvider);
      expect(result.hasHidden, false);
      expect(result.activeHidden, 0);
    });

    test('calculates hidden unscheduled tasks count correctly', () async {
      final now = DateTime.now();
      final t1 = Task(
        id: 't1',
        title: 'Urgent Task',
        isUrgent: true,
        createdAt: now,
      );
      final t2 = Task(
        id: 't2',
        title: 'Normal Task',
        isUrgent: false,
        createdAt: now,
      );

      when(
        () => mockTaskRepo.getUnscheduled(),
      ).thenAnswer((_) async => [t1, t2]);
      await container.read(taskProvider.notifier).loadUnscheduledTasks();

      container
          .read(filterProvider.notifier)
          .setFilter(const TaskFilter(isUrgent: true));

      final hiddenCount = container.read(hiddenUnscheduledTasksCountProvider);
      expect(hiddenCount, 1);
    });

    test(
      'scopes hidden unscheduled tasks count to the active label tab',
      () async {
        final now = DateTime.now();
        final t1 = Task(
          id: 't1',
          title: 'Work Task',
          labelIds: ['l1'],
          isUrgent: false,
          createdAt: now,
        );
        final t2 = Task(
          id: 't2',
          title: 'Personal Task',
          labelIds: ['l2'],
          isUrgent: false,
          createdAt: now,
        );
        final t3 = Task(
          id: 't3',
          title: 'Inbox Task',
          labelIds: [],
          isUrgent: false,
          createdAt: now,
        );

        when(
          () => mockTaskRepo.getUnscheduled(),
        ).thenAnswer((_) async => [t1, t2, t3]);
        await container.read(taskProvider.notifier).loadUnscheduledTasks();

        container
            .read(filterProvider.notifier)
            .setFilter(const TaskFilter(isUrgent: true));

        // Tab 'all' -> all 3 hidden
        container.read(backlogLabelTabProvider.notifier).selectAll();
        expect(container.read(hiddenUnscheduledTasksCountProvider), 3);

        // Tab 'l1' -> only 1 hidden
        container.read(backlogLabelTabProvider.notifier).selectLabel('l1');
        expect(container.read(hiddenUnscheduledTasksCountProvider), 1);

        // Tab 'inbox' -> only 1 hidden
        container.read(backlogLabelTabProvider.notifier).selectInbox();
        expect(container.read(hiddenUnscheduledTasksCountProvider), 1);

        // Tab 'l3' -> 0 hidden
        container.read(backlogLabelTabProvider.notifier).selectLabel('l3');
        expect(container.read(hiddenUnscheduledTasksCountProvider), 0);
      },
    );
  });
}
