import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('tasks scheduling cascade', () {
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

    test(
      'scheduleTasksForToday cascades date to unscheduled child subtasks',
      () async {
        final parent = createTestTask(id: 'p1', title: 'Parent');
        final unscheduledSubtask = createTestTask(
          id: 'sub1',
          title: 'Sub 1',
          parentId: 'p1',
          scheduledDate: null,
        );

        when(() => mockTaskRepo.getById('p1')).thenAnswer((_) async => parent);
        when(
          () => mockTaskRepo.getByParent('p1'),
        ).thenAnswer((_) async => [unscheduledSubtask]);
        when(
          () => mockTaskRepo.getByParent('sub1'),
        ).thenAnswer((_) async => []);
        when(() => mockTaskRepo.update(any())).thenAnswer((_) async => {});

        final notifier = container.read(taskProvider.notifier);
        await notifier.scheduleTasksForToday(['p1']);

        verify(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'p1')),
          ),
        ).called(1);
        verify(
          () => mockTaskRepo.update(
            any(that: isA<Task>().having((t) => t.id, 'id', 'sub1')),
          ),
        ).called(1);
      },
    );
  });
}
