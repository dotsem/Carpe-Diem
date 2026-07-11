import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const Tag(id: '', name: ''));
  });

  group('tags', () {
    late MockTagRepository mockRepo;
    late MockProjectRepository mockProjectRepo;
    late MockTaskRepository mockTaskRepo;
    late MockHistoryRepository mockHistoryRepo;
    late MockSettingsRepository mockSettingsRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockTagRepository();
      mockProjectRepo = MockProjectRepository();
      mockTaskRepo = MockTaskRepository();
      mockHistoryRepo = MockHistoryRepository();
      mockSettingsRepo = MockSettingsRepository();

      when(() => mockRepo.repositoryName).thenReturn('tags');
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines'))).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getUnscheduled(prioritizeDeadlines: any(named: 'prioritizeDeadlines'))).thenAnswer((_) async => []);
      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          tagRepositoryProvider.overrideWithValue(mockRepo),
          projectRepositoryProvider.overrideWithValue(mockProjectRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty state and load tags successfully', () async {
      final initial = container.read(tagProvider);
      expect(initial.tags, isEmpty);
      expect(initial.isLoading, isFalse);

      final dummyTag = const Tag(id: 't1', name: 'urgent');
      when(() => mockRepo.getAll()).thenAnswer((_) async => [dummyTag]);

      await container.read(tagProvider.notifier).loadTags();

      final updated = container.read(tagProvider);
      expect(updated.tags.length, equals(1));
      expect(updated.tags.first.id, equals('t1'));
      verify(() => mockRepo.getAll()).called(1);
    });

    test('should add tag, call insert, and trigger reload', () async {
      when(() => mockRepo.insert(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);

      final tag = await container.read(tagProvider.notifier).addTag('work');

      expect(tag.name, equals('work'));
      verify(() => mockRepo.insert(any())).called(1);
      verify(() => mockRepo.getAll()).called(1);
    });

    test('should update tag, call update, and trigger reload', () async {
      final tag = const Tag(id: 't1', name: 'work');
      when(() => mockRepo.getById('t1')).thenAnswer((_) async => tag);
      when(() => mockRepo.update(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => [tag]);

      await container.read(tagProvider.notifier).updateTag(tag.copyWith(name: 'work-updated'));

      verify(() => mockRepo.update(any())).called(1);
      verify(() => mockRepo.getAll()).called(1);
    });

    test('should delete tag, call delete, and trigger reload', () async {
      final tag = const Tag(id: 't1', name: 'work');
      when(() => mockRepo.getById('t1')).thenAnswer((_) async => tag);
      when(() => mockRepo.delete('t1')).thenAnswer((_) async => {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);

      await container.read(tagProvider.notifier).deleteTag('t1');

      verify(() => mockRepo.delete('t1')).called(1);
      verify(() => mockRepo.getAll()).called(1);
    });
  });
}
