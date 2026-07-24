import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  group('filter', () {
    late MockSettingsRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockSettingsRepository();
      when(() => mockRepo.getAll()).thenAnswer((_) async => {});
      when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockRepo),
        ],
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

    test('toggleBypass hides the active filter but preserves the original filter config', () {
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

    test('initializes with persisted filter when persistentFilter is true', () async {
      final persistedFilter = const TaskFilter(isUrgent: true);
      when(() => mockRepo.getAll()).thenAnswer((_) async => {
        'persistent_filter': 'true',
        'persistent_filter_values': jsonEncode(persistedFilter.toMap()),
      });

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(filterProvider);
      expect(state.filter.isUrgent, true);
    });

    test('does not initialize with persisted filter when persistentFilter is false', () async {
      final persistedFilter = const TaskFilter(isUrgent: true);
      when(() => mockRepo.getAll()).thenAnswer((_) async => {
        'persistent_filter': 'false',
        'persistent_filter_values': jsonEncode(persistedFilter.toMap()),
      });

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(filterProvider);
      expect(state.filter.isEmpty, true);
    });

    test('setFilter updates repository when persistentFilter is true', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => {
        'persistent_filter': 'true',
      });
      await container.read(settingsProvider.notifier).loadSettings();

      const newFilter = TaskFilter(isUrgent: false);
      container.read(filterProvider.notifier).setFilter(newFilter);

      // Wait a microtask to allow async database write to trigger
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.set('persistent_filter_values', jsonEncode(newFilter.toMap()))).called(1);
    });

    test('clearFilter clears repository when persistentFilter is true', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => {
        'persistent_filter': 'true',
      });
      await container.read(settingsProvider.notifier).loadSettings();

      const filter = TaskFilter(isUrgent: false);
      final notifier = container.read(filterProvider.notifier);
      notifier.setFilter(filter);
      notifier.clearFilter();

      await Future.delayed(Duration.zero);

      verify(() => mockRepo.set('persistent_filter_values', jsonEncode(const TaskFilter().toMap()))).called(1);
    });
  });
}
