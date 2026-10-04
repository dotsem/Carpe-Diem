import 'dart:convert';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  group('filter_modes_provider', () {
    late MockKeyValueRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockKeyValueRepository();
      when(() => mockRepo.getAll()).thenAnswer((_) async => {});
      when(() => mockRepo.set(any(), any())).thenAnswer((_) async => {});
      when(() => mockRepo.get(any())).thenAnswer((_) async => null);

      container = ProviderContainer(
        overrides: [keyValueRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadModes populates state from key-value repository', () async {
      const mode = FilterMode(
        id: 'mode-1',
        name: 'Work',
        filter: TaskFilter(isUrgent: true),
      );
      final json = jsonEncode([mode.toMap()]);
      when(() => mockRepo.get(keyFilterModes)).thenAnswer((_) async => json);

      await container.read(filterModesProvider.notifier).loadModes();

      final state = container.read(filterModesProvider);
      expect(state.modes.length, 1);
      expect(state.modes.first.name, 'Work');
      expect(state.modes.first.filter.isUrgent, isTrue);
    });

    test('createMode appends mode and persists it', () async {
      const filter = TaskFilter(projectIdsIncluded: {'proj-1'});
      final created = await container
          .read(filterModesProvider.notifier)
          .createMode(name: 'School', filter: filter);

      expect(created.name, 'School');
      expect(created.filter, filter);

      final state = container.read(filterModesProvider);
      expect(state.modes.length, 1);
      expect(state.modes.first.id, created.id);

      verify(() => mockRepo.set(keyFilterModes, any())).called(1);
    });

    test('updateMode updates existing mode name and filter', () async {
      final created = await container
          .read(filterModesProvider.notifier)
          .createMode(name: 'Work', filter: const TaskFilter(isUrgent: true));

      final updated = created.copyWith(
        name: 'Job',
        filter: const TaskFilter(isUrgent: false),
      );
      await container.read(filterModesProvider.notifier).updateMode(updated);

      final state = container.read(filterModesProvider);
      expect(state.modes.first.name, 'Job');
      expect(state.modes.first.filter.isUrgent, isFalse);
    });

    test('deleteMode removes mode by id', () async {
      final created = await container
          .read(filterModesProvider.notifier)
          .createMode(
            name: 'Gym',
            filter: const TaskFilter(tagIdsIncluded: {'gym'}),
          );

      expect(container.read(filterModesProvider).modes.length, 1);

      await container.read(filterModesProvider.notifier).deleteMode(created.id);
      expect(container.read(filterModesProvider).modes, isEmpty);
    });

    test(
      'activeFilterModeProvider accurately derives active mode and custom states',
      () async {
        const filter = TaskFilter(labelIdsIncluded: {'label-work'});
        final created = await container
            .read(filterModesProvider.notifier)
            .createMode(name: 'Work', filter: filter);

        expect(container.read(activeFilterModeProvider), isNull);

        container.read(filterProvider.notifier).setFilter(filter);
        expect(container.read(activeFilterModeProvider)?.id, created.id);

        container.read(filterProvider.notifier).setUrgentFilter(true);
        expect(container.read(activeFilterModeProvider), isNull);

        container.read(filterProvider.notifier).clearFilter();
        expect(container.read(activeFilterModeProvider), isNull);
      },
    );
  });
}
