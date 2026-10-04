import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/save_mode_dialog.dart';
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

  group('save_mode_dialog validation', () {
    late MockKeyValueRepository mockRepo;
    late MockFilterModeRepository mockFilterModeRepo;
    late Map<String, String> storage;
    late List<FilterMode> modeStorage;

    setUp(() {
      storage = {};
      modeStorage = [];
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

    Widget buildTestWidget({
      ProviderContainer? container,
      String? initialName,
      int? initialIconCodePoint,
      void Function(SaveModeResult?)? onResult,
    }) {
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
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    final res = await showDialog<SaveModeResult>(
                      context: context,
                      builder: (ctx) => SaveModeDialog(
                        initialName: initialName,
                        initialIconCodePoint: initialIconCodePoint,
                      ),
                    );
                    onResult?.call(res);
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('shows error when mode name is empty or only whitespace', (
      tester,
    ) async {
      SaveModeResult? returned;
      await tester.pumpWidget(
        buildTestWidget(onResult: (val) => returned = val),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Mode name cannot be empty'), findsOneWidget);
      expect(find.byType(SaveModeDialog), findsOneWidget);
      expect(returned, isNull);
    });

    testWidgets('shows error when mode name is reserved / illegal', (
      tester,
    ) async {
      const illegalNames = [
        'custom',
        'Custom',
        'no mode',
        'No Mode',
        'no_mode',
        'no-mode',
      ];

      for (final name in illegalNames) {
        SaveModeResult? returned;
        await tester.pumpWidget(
          buildTestWidget(onResult: (val) => returned = val),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), name);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(
          find.text('This mode name is reserved for internal use'),
          findsOneWidget,
        );
        expect(find.byType(SaveModeDialog), findsOneWidget);
        expect(returned, isNull);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
      'shows error when mode name already exists (case-insensitive)',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            keyValueRepositoryProvider.overrideWithValue(mockRepo),
            filterModeRepositoryProvider.overrideWithValue(mockFilterModeRepo),
          ],
        );

        await container
            .read(filterModesProvider.notifier)
            .createMode(name: 'Work', filter: const TaskFilter());

        SaveModeResult? returned;
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            onResult: (val) => returned = val,
          ),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'work');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(
          find.text('A mode with this name already exists'),
          findsOneWidget,
        );
        expect(find.byType(SaveModeDialog), findsOneWidget);
        expect(returned, isNull);
      },
    );

    testWidgets('submits successfully when mode name is valid and unique', (
      tester,
    ) async {
      SaveModeResult? returned;
      await tester.pumpWidget(
        buildTestWidget(onResult: (val) => returned = val),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Free Time  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SaveModeDialog), findsNothing);
      expect(returned?.name, 'Free Time');
      expect(returned?.iconCodePoint, Icons.tune.codePoint);
    });

    testWidgets('allows selecting an icon from the icon picker', (
      tester,
    ) async {
      SaveModeResult? returned;
      await tester.pumpWidget(
        buildTestWidget(onResult: (val) => returned = val),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'School');
      await tester.tap(find.byIcon(Icons.school));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SaveModeDialog), findsNothing);
      expect(returned?.name, 'School');
      expect(returned?.iconCodePoint, Icons.school.codePoint);
    });
  });
}
