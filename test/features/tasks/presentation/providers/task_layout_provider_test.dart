import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_layout_provider.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('task_layout', () {
    late MockKeyValueRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockKeyValueRepository();
      container = ProviderContainer(
        overrides: [keyValueRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state defaults to TaskLayout.list', () {
      final state = container.read(taskLayoutProvider);
      expect(state, equals(TaskLayout.list));
    });

    test('loadTaskLayout restores layout from repository', () async {
      when(() => mockRepo.get(keyTaskLayout)).thenAnswer((_) async => 'kanban');

      await container.read(taskLayoutProvider.notifier).loadTaskLayout();

      expect(container.read(taskLayoutProvider), equals(TaskLayout.kanban));
      verify(() => mockRepo.get(keyTaskLayout)).called(1);
    });

    test('loadTaskLayout defaults to list on null or unknown value', () async {
      when(() => mockRepo.get(keyTaskLayout)).thenAnswer((_) async => null);

      await container.read(taskLayoutProvider.notifier).loadTaskLayout();
      expect(container.read(taskLayoutProvider), equals(TaskLayout.list));

      when(
        () => mockRepo.get(keyTaskLayout),
      ).thenAnswer((_) async => 'unknown_mode');

      await container.read(taskLayoutProvider.notifier).loadTaskLayout();
      expect(container.read(taskLayoutProvider), equals(TaskLayout.list));
    });

    test('setLayout updates state and saves to repository', () async {
      when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});

      await container
          .read(taskLayoutProvider.notifier)
          .setLayout(TaskLayout.kanban);

      expect(container.read(taskLayoutProvider), equals(TaskLayout.kanban));
      verify(() => mockRepo.set(keyTaskLayout, 'kanban')).called(1);
    });

    test('toggleLayout switches between list and kanban', () async {
      when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});

      final notifier = container.read(taskLayoutProvider.notifier);

      await notifier.toggleLayout();
      expect(container.read(taskLayoutProvider), equals(TaskLayout.kanban));
      verify(() => mockRepo.set(keyTaskLayout, 'kanban')).called(1);

      await notifier.toggleLayout();
      expect(container.read(taskLayoutProvider), equals(TaskLayout.list));
      verify(() => mockRepo.set(keyTaskLayout, 'list')).called(1);
    });
  });
}
