import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/data/models/tag_profile.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const Tag(id: '', name: ''));
    registerFallbackValue(Icons.tag);
  });

  group('tag_profile', () {
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockTagIconRepo;
    late MockProjectRepository mockProjectRepo;
    late MockTaskRepository mockTaskRepo;
    late MockHistoryRepository mockHistoryRepo;
    late MockSettingsRepository mockSettingsRepo;
    late ProviderContainer container;

    setUp(() {
      mockTagRepo = MockTagRepository();
      mockTagIconRepo = MockTagIconRepository();
      mockProjectRepo = MockProjectRepository();
      mockTaskRepo = MockTaskRepository();
      mockHistoryRepo = MockHistoryRepository();
      mockSettingsRepo = MockSettingsRepository();

      when(() => mockTagRepo.repositoryName).thenReturn('tags');
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getAll()).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getByDate(any(), prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getUnscheduled(prioritizeDeadlines: any(named: 'prioritizeDeadlines')),
      ).thenAnswer((_) async => []);
      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});

      when(() => mockTagIconRepo.getAllIconDatas()).thenAnswer((_) async => {});
      when(() => mockTagIconRepo.setIconDataForTag(any(), any())).thenAnswer((_) async => {});
      when(() => mockTagIconRepo.deleteIconDataForTag(any())).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          tagRepositoryProvider.overrideWithValue(mockTagRepo),
          tagIconRepositoryProvider.overrideWithValue(mockTagIconRepo),
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

    test('should populate profile tags and skip duplicates', () async {
      final existingTag = const Tag(id: 't1', name: 'bug');
      when(() => mockTagRepo.getAll()).thenAnswer((_) async => [existingTag]);
      when(() => mockTagRepo.insert(any())).thenAnswer((_) async => {});

      await container.read(tagProvider.notifier).loadTags();
      expect(container.read(tagProvider).tags.length, 1);

      final programmingProfile = TagProfile.predefinedProfiles.firstWhere((p) => p.name.contains('Programming'));

      await container.read(tagProvider.notifier).populateProfile(programmingProfile);

      // programming profile has 9 tags. since 'bug' exists, insert should be called 8 times.
      verify(() => mockTagRepo.insert(any())).called(8);
      verify(() => mockTagIconRepo.setIconDataForTag(any(), any())).called(9);
    });

    test('should undo and redo compound populate command', () async {
      when(() => mockTagRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockTagRepo.insert(any())).thenAnswer((_) async => {});
      when(() => mockTagRepo.delete(any())).thenAnswer((_) async => {});

      final programmingProfile = TagProfile.predefinedProfiles.firstWhere((p) => p.name.contains('Programming'));

      await container.read(tagProvider.notifier).populateProfile(programmingProfile);

      await container.read(undoRedoProvider.notifier).undo();

      verify(() => mockTagRepo.delete(any())).called(9);
      verify(() => mockTagIconRepo.deleteIconDataForTag(any())).called(9);
    });
  });
}
