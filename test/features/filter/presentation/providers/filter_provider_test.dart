import 'dart:convert';

import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  group('filter', () {
    late MockKeyValueRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockKeyValueRepository();
      when(() => mockRepo.getAll()).thenAnswer((_) async => {});
      when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});
      when(() => mockRepo.get(any())).thenAnswer((_) async => null);
      when(() => mockRepo.delete(any())).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [keyValueRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty filter with no bypass', () {
      final state = container.read(filterProvider);
      expect(state.filter.isEmpty, true);
      expect(state.isBypassed, false);
      expect(state.activeFilter.isEmpty, true);
    });

    test('setFilter updates the state filter', () {
      const newFilter = TaskFilter(isUrgent: true);

      container.read(filterProvider.notifier).setFilter(newFilter);

      final state = container.read(filterProvider);
      expect(state.filter.isUrgent, true);
      expect(state.activeFilter.isUrgent, true);
    });

    test(
      'toggleBypass hides the active filter but preserves the original filter config',
      () {
        const filter = TaskFilter(isUrgent: true);
        final notifier = container.read(filterProvider.notifier);

        notifier.setFilter(filter);
        notifier.toggleBypass();

        final state = container.read(filterProvider);
        expect(state.isBypassed, true);
        expect(state.filter.isUrgent, true);
        expect(state.activeFilter.isEmpty, true);

        notifier.toggleBypass();
        final stateAfterSecondToggle = container.read(filterProvider);
        expect(stateAfterSecondToggle.isBypassed, false);
        expect(stateAfterSecondToggle.activeFilter.isUrgent, true);
      },
    );

    test('toggleBypass does nothing when the filter is empty', () {
      container.read(filterProvider.notifier).toggleBypass();

      expect(container.read(filterProvider).isBypassed, false);
    });

    test('clearFilter resets the filter and bypass settings', () {
      const filter = TaskFilter(isUrgent: false);
      final notifier = container.read(filterProvider.notifier);

      notifier.setFilter(filter);
      notifier.toggleBypass();
      notifier.clearFilter();

      final state = container.read(filterProvider);
      expect(state.filter.isEmpty, true);
      expect(state.isBypassed, false);
      expect(state.activeFilter.isEmpty, true);
    });

    test(
      'initializes with persisted filter when persistentFilter is true',
      () async {
        const persistedFilter = TaskFilter(isUrgent: true);
        when(
          () => mockRepo.getAll(),
        ).thenAnswer((_) async => {'persistent_filter': 'true'});
        when(
          () => mockRepo.get('persistent_filter_values'),
        ).thenAnswer((_) async => jsonEncode(persistedFilter.toMap()));

        await container.read(settingsProvider.notifier).loadSettings();
        await container.read(filterProvider.notifier).loadFilter();

        final state = container.read(filterProvider);
        expect(state.filter.isUrgent, true);
      },
    );

    test(
      'does not initialize with persisted filter when persistentFilter is false',
      () async {
        const persistedFilter = TaskFilter(isUrgent: true);
        when(
          () => mockRepo.getAll(),
        ).thenAnswer((_) async => {'persistent_filter': 'false'});
        when(
          () => mockRepo.get('persistent_filter_values'),
        ).thenAnswer((_) async => jsonEncode(persistedFilter.toMap()));

        await container.read(settingsProvider.notifier).loadSettings();
        await container.read(filterProvider.notifier).loadFilter();

        final state = container.read(filterProvider);
        expect(state.filter.isEmpty, true);
      },
    );

    test(
      'setFilter updates repository when persistentFilter is true',
      () async {
        when(
          () => mockRepo.getAll(),
        ).thenAnswer((_) async => {'persistent_filter': 'true'});
        await container.read(settingsProvider.notifier).loadSettings();

        const newFilter = TaskFilter(isUrgent: false);
        container.read(filterProvider.notifier).setFilter(newFilter);

        // Wait a microtask to allow async database write to trigger
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockRepo.set(
            'persistent_filter_values',
            jsonEncode(newFilter.toMap()),
          ),
        ).called(1);
      },
    );

    test(
      'clearFilter clears repository when persistentFilter is true',
      () async {
        when(
          () => mockRepo.getAll(),
        ).thenAnswer((_) async => {'persistent_filter': 'true'});
        await container.read(settingsProvider.notifier).loadSettings();

        const filter = TaskFilter(isUrgent: false);
        final notifier = container.read(filterProvider.notifier);
        notifier.setFilter(filter);
        notifier.clearFilter();

        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockRepo.set(
            'persistent_filter_values',
            jsonEncode(const TaskFilter().toMap()),
          ),
        ).called(1);
      },
    );

    test('removes included and excluded filters for every category', () {
      final notifier = container.read(filterProvider.notifier);
      notifier.setFilter(
        const TaskFilter(
          labelIdsIncluded: {'li'},
          labelIdsExcluded: {'le'},
          projectIdsIncluded: {'pi'},
          projectIdsExcluded: {'pe'},
          tagIdsIncluded: {'ti'},
          tagIdsExcluded: {'te'},
        ),
      );

      notifier.removeLabelFilter('li');
      notifier.removeLabelFilter('le');
      notifier.removeProjectFilter('pi');
      notifier.removeProjectFilter('pe');
      notifier.removeTagFilter('ti');
      notifier.removeTagFilter('te');
      notifier.removeTagFilter('missing');

      expect(container.read(filterProvider).filter.isEmpty, isTrue);
    });

    test('clearPersistedFilter deletes the stored filter', () async {
      await container.read(filterProvider.notifier).clearPersistedFilter();

      verify(() => mockRepo.delete(keyPersistentFilterValues)).called(1);
    });

    test('persistence failures leave the in-memory filter usable', () async {
      when(
        () => mockRepo.getAll(),
      ).thenAnswer((_) async => {'persistent_filter': 'true'});
      when(
        () => mockRepo.get(any()),
      ).thenThrow(const FormatException('bad json'));
      when(() => mockRepo.set(any(), any())).thenThrow(StateError('write'));
      when(() => mockRepo.delete(any())).thenThrow(StateError('delete'));
      await container.read(settingsProvider.notifier).loadSettings();
      final notifier = container.read(filterProvider.notifier);

      await notifier.loadFilter();
      notifier.setUrgentFilter(true);
      await notifier.saveFilter();
      await notifier.clearPersistedFilter();

      expect(container.read(filterProvider).filter.isUrgent, isTrue);
    });
  });
}
