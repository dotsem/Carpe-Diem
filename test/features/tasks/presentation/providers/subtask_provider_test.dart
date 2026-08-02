import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  group('tasks', () {
    late TestTaskRepositories repos;
    late MockTaskRepository mockTaskRepo;
    late ProviderContainer container;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
      mockTaskRepo = repos.mockTaskRepo;
      container = repos.createContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('subtasksProvider returns all subtasks for given parent ID', () async {
      final subtasks = [
        createTestTask(id: 'sub1', title: 'Sub 1', parentId: 'parent1'),
        createTestTask(id: 'sub2', title: 'Sub 2', parentId: 'parent1'),
      ];

      when(
        () => mockTaskRepo.getByParent('parent1'),
      ).thenAnswer((_) async => subtasks);

      final result = await container.read(subtasksProvider('parent1').future);

      expect(result.length, equals(2));
      expect(result[0].id, equals('sub1'));
      expect(result[1].id, equals('sub2'));
      verify(() => mockTaskRepo.getByParent('parent1')).called(1);
    });

    test('parentTaskProvider returns parent task by ID', () async {
      final parent = createTestTask(id: 'parent1', title: 'Parent Task');

      when(
        () => mockTaskRepo.getById('parent1'),
      ).thenAnswer((_) async => parent);

      final result = await container.read(parentTaskProvider('parent1').future);

      expect(result, isNotNull);
      expect(result!.title, equals('Parent Task'));
      verify(() => mockTaskRepo.getById('parent1')).called(1);
    });

    test(
      'collapsedSubtasksProvider toggles and reports collapse state correctly',
      () {
        final notifier = container.read(collapsedSubtasksProvider.notifier);

        expect(notifier.isCollapsed('p1'), isFalse);
        expect(
          container.read(collapsedSubtasksProvider).contains('p1'),
          isFalse,
        );

        notifier.toggleCollapse('p1');
        expect(notifier.isCollapsed('p1'), isTrue);
        expect(
          container.read(collapsedSubtasksProvider).contains('p1'),
          isTrue,
        );

        notifier.toggleCollapse('p1');
        expect(notifier.isCollapsed('p1'), isFalse);
        expect(
          container.read(collapsedSubtasksProvider).contains('p1'),
          isFalse,
        );
      },
    );
  });
}
