import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/mode_selection_dialog.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  group('ModeSelectionDialog', () {
    late MockKeyValueRepository mockRepo;
    late MockFilterModeRepository mockFilterModeRepo;
    late List<FilterMode> modeStorage;
    late Map<String, String> storage;

    setUp(() {
      storage = {};
      modeStorage = [
        const FilterMode(
          id: 'm1',
          name: 'Work',
          filter: TaskFilter(isUrgent: true),
        ),
        const FilterMode(
          id: 'm2',
          name: 'School',
          filter: TaskFilter(projectIdsIncluded: {'proj-1'}),
        ),
      ];
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
    });

    Widget buildTestWidget({required ProviderContainer container}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: Scaffold(
            body: GlobalShortcuts(
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => ModeSelectionDialog.show(context),
                        child: const Text('Open Modes'),
                      ),
                      const TextField(key: Key('test_input')),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders No Mode and all saved modes with badges', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockRepo),
          filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
        ],
      );
      await container.read(filterModesProvider.notifier).loadModes();

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.tap(find.text('Open Modes'));
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectionDialog), findsOneWidget);
      expect(find.text('No Mode'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('selecting a mode applies filter and activeModeId', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockRepo),
          filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
        ],
      );
      await container.read(filterModesProvider.notifier).loadModes();

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.tap(find.text('Open Modes'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectionDialog), findsNothing);
      expect(container.read(filterProvider).filter.isUrgent, isTrue);
      expect(container.read(filterModesProvider).activeModeId, 'm1');
    });

    testWidgets('number keys trigger mode selection directly', (tester) async {
      final container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockRepo),
          filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
        ],
      );
      await container.read(filterModesProvider.notifier).loadModes();

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.tap(find.text('Open Modes'));
      await tester.pumpAndSettle();

      // Press '2' for School
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectionDialog), findsNothing);
      expect(
        container.read(filterProvider).filter.projectIdsIncluded,
        contains('proj-1'),
      );
      expect(container.read(filterModesProvider).activeModeId, 'm2');
    });

    testWidgets('global "m" shortcut opens mode dialog when not typing', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockRepo),
          filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
        ],
      );
      await container.read(filterModesProvider.notifier).loadModes();

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectionDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ModeSelectionDialog), findsNothing);
    });

    testWidgets(
      'global "m" shortcut does NOT open dialog when typing in text field',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            keyValueRepositoryProvider.overrideWithValue(mockRepo),
            filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
          ],
        );
        await container.read(filterModesProvider.notifier).loadModes();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('test_input')));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
        await tester.pumpAndSettle();

        expect(find.byType(ModeSelectionDialog), findsNothing);
      },
    );
  });
}
