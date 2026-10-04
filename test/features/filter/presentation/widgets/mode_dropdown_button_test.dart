import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/mode_dropdown_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      const FilterMode(id: '', name: '', filter: TaskFilter()),
    );
  });

  group('mode_dropdown_button', () {
    late MockKeyValueRepository mockRepo;
    late MockFilterModeRepository mockFilterModeRepo;
    final storage = <String, String>{};
    final modeStorage = <FilterMode>[];

    setUp(() {
      storage.clear();
      modeStorage.clear();
      mockRepo = MockKeyValueRepository();
      mockFilterModeRepo = MockFilterModeRepository();

      when(() => mockRepo.getAll()).thenAnswer((_) async => storage);
      when(() => mockRepo.set(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1] as String;
      });
      when(() => mockRepo.get(any())).thenAnswer((inv) async {
        return storage[inv.positionalArguments[0] as String];
      });
      when(() => mockRepo.delete(any())).thenAnswer((inv) async {
        storage.remove(inv.positionalArguments[0] as String);
      });

      when(
        () => mockFilterModeRepo.getAll(),
      ).thenAnswer((_) async => modeStorage);
      when(() => mockFilterModeRepo.insert(any())).thenAnswer((inv) async {
        modeStorage.add(inv.positionalArguments[0] as FilterMode);
      });
      when(() => mockFilterModeRepo.update(any())).thenAnswer((inv) async {
        final updated = inv.positionalArguments[0] as FilterMode;
        final idx = modeStorage.indexWhere((m) => m.id == updated.id);
        if (idx != -1) modeStorage[idx] = updated;
      });
      when(() => mockFilterModeRepo.delete(any())).thenAnswer((inv) async {
        final id = inv.positionalArguments[0] as String;
        modeStorage.removeWhere((m) => m.id == id);
      });
    });

    Widget buildTestWidget({ProviderContainer? container}) {
      return UncontrolledProviderScope(
        container:
            container ??
            ProviderContainer(
              overrides: [
                keyValueRepositoryProvider.overrideWithValue(mockRepo),
                filterModeRepositoryProvider.overrideWithValue(
                  mockFilterModeRepo,
                ),
              ],
            ),
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ModeDropdownButton())),
        ),
      );
    }

    testWidgets('displays "Mode: No Mode" by default', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mode: No Mode'), findsOneWidget);
    });

    testWidgets('displays "Mode: Custom" when filter is active and unmatched', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockRepo),
          filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
        ],
      );

      container.read(filterProvider.notifier).setUrgentFilter(true);

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Mode: Custom'), findsOneWidget);
    });

    testWidgets('displays mode name when filter matches an existing mode', (
      tester,
    ) async {
      const filter = TaskFilter(isUrgent: true);
      final container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockRepo),
          filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
        ],
      );

      await container
          .read(filterModesProvider.notifier)
          .createMode(name: 'Work', filter: filter);
      container.read(filterProvider.notifier).setFilter(filter);

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Mode: Work'), findsOneWidget);
    });

    testWidgets('opens popup menu on tap and allows selecting a mode', (
      tester,
    ) async {
      const filter = TaskFilter(projectIdsIncluded: {'proj-1'});
      final container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockRepo),
          filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
        ],
      );

      await container
          .read(filterModesProvider.notifier)
          .createMode(name: 'School', filter: filter);

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ModeDropdownButton));
      await tester.pumpAndSettle();

      expect(find.text('School'), findsOneWidget);
      expect(find.text('No Mode'), findsOneWidget);
      expect(find.text('Save as mode...'), findsOneWidget);
      expect(find.text('Manage modes...'), findsOneWidget);

      await tester.tap(find.text('School'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(container.read(filterProvider).filter, filter);
      expect(find.text('Mode: School'), findsOneWidget);
    });
  });
}
