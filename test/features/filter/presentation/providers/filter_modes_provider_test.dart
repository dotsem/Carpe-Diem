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
  setUpAll(() {
    registerFallbackValue(
      const FilterMode(id: '', name: '', filter: TaskFilter()),
    );
  });

  group('filter_modes_provider', () {
    late MockFilterModeRepository mockModeRepo;
    late MockKeyValueRepository mockKvRepo;
    late ProviderContainer container;

    setUp(() {
      mockModeRepo = MockFilterModeRepository();
      mockKvRepo = MockKeyValueRepository();
      when(() => mockModeRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockModeRepo.insert(any())).thenAnswer((_) async {});
      when(() => mockModeRepo.update(any())).thenAnswer((_) async {});
      when(() => mockModeRepo.delete(any())).thenAnswer((_) async {});
      when(() => mockKvRepo.get(any())).thenAnswer((_) async => null);
      when(() => mockKvRepo.set(any(), any())).thenAnswer((_) async {});
      when(() => mockKvRepo.delete(any())).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          filterModeRepositoryProvider.overrideWithValue(mockModeRepo),
          keyValueRepositoryProvider.overrideWithValue(mockKvRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'loadModes populates state from filter mode repository and kv repository',
      () async {
        const mode = FilterMode(
          id: 'mode-1',
          name: 'Work',
          filter: TaskFilter(isUrgent: true),
        );
        when(() => mockModeRepo.getAll()).thenAnswer((_) async => [mode]);
        when(
          () => mockKvRepo.get(keyActiveFilterMode),
        ).thenAnswer((_) async => 'mode-1');

        await container.read(filterModesProvider.notifier).loadModes();

        final state = container.read(filterModesProvider);
        expect(state.modes.length, 1);
        expect(state.modes.first.name, 'Work');
        expect(state.modes.first.filter.isUrgent, isTrue);
        expect(state.activeModeId, 'mode-1');
      },
    );

    test('createMode inserts mode into repository and updates state', () async {
      const filter = TaskFilter(projectIdsIncluded: {'proj-1'});
      final created = await container
          .read(filterModesProvider.notifier)
          .createMode(name: 'School', filter: filter, iconCodePoint: 0xe559);

      expect(created.name, 'School');
      expect(created.filter, filter);
      expect(created.iconCodePoint, 0xe559);

      final state = container.read(filterModesProvider);
      expect(state.modes.length, 1);
      expect(state.modes.first.id, created.id);
      expect(state.modes.first.iconCodePoint, 0xe559);

      verify(() => mockModeRepo.insert(any())).called(1);
    });

    test('updateMode updates existing mode in repository', () async {
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
      verify(() => mockModeRepo.update(updated)).called(1);
    });

    test(
      'deleteMode removes mode by id and clears active mode if it was active',
      () async {
        final created = await container
            .read(filterModesProvider.notifier)
            .createMode(
              name: 'Gym',
              filter: const TaskFilter(tagIdsIncluded: {'gym'}),
            );

        await container
            .read(filterModesProvider.notifier)
            .setActiveModeId(created.id);
        expect(container.read(filterModesProvider).activeModeId, created.id);

        await container
            .read(filterModesProvider.notifier)
            .deleteMode(created.id);
        expect(container.read(filterModesProvider).modes, isEmpty);
        expect(container.read(filterModesProvider).activeModeId, isNull);
        verify(() => mockModeRepo.delete(created.id)).called(1);
        verify(() => mockKvRepo.delete(keyActiveFilterMode)).called(1);
      },
    );

    test(
      'setActiveModeId persists active mode id and deletes on null',
      () async {
        await container
            .read(filterModesProvider.notifier)
            .setActiveModeId('mode-123');
        expect(container.read(filterModesProvider).activeModeId, 'mode-123');
        verify(() => mockKvRepo.set(keyActiveFilterMode, 'mode-123')).called(1);

        await container
            .read(filterModesProvider.notifier)
            .setActiveModeId(null);
        expect(container.read(filterModesProvider).activeModeId, isNull);
        verify(() => mockKvRepo.delete(keyActiveFilterMode)).called(1);
      },
    );

    test(
      'activeFilterModeProvider accurately derives active mode and custom states',
      () async {
        const filter = TaskFilter(labelIdsIncluded: {'label-work'});
        final created = await container
            .read(filterModesProvider.notifier)
            .createMode(name: 'Work', filter: filter);

        expect(container.read(activeFilterModeProvider), isNull);

        await container
            .read(filterModesProvider.notifier)
            .setActiveModeId(created.id);
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
