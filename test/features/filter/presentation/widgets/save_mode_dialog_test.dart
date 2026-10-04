import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/save_mode_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_repositories.dart';

void main() {
  group('save_mode_dialog validation', () {
    late MockKeyValueRepository mockRepo;
    late Map<String, String> storage;

    setUp(() {
      storage = {};
      mockRepo = MockKeyValueRepository();
      when(() => mockRepo.getAll()).thenAnswer((_) async => storage);
      when(() => mockRepo.set(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1] as String;
      });
      when(() => mockRepo.get(any())).thenAnswer((inv) async {
        return storage[inv.positionalArguments[0] as String];
      });
    });

    Widget buildTestWidget({
      ProviderContainer? container,
      String? initialName,
      void Function(String?)? onResult,
    }) {
      return UncontrolledProviderScope(
        container:
            container ??
            ProviderContainer(
              overrides: [
                keyValueRepositoryProvider.overrideWithValue(mockRepo),
              ],
            ),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    final res = await showDialog<String>(
                      context: context,
                      builder: (ctx) =>
                          SaveModeDialog(initialName: initialName),
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
      String? returnedName;
      await tester.pumpWidget(
        buildTestWidget(onResult: (val) => returnedName = val),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Mode name cannot be empty'), findsOneWidget);
      expect(find.byType(SaveModeDialog), findsOneWidget);
      expect(returnedName, isNull);
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
        String? returnedName;
        await tester.pumpWidget(
          buildTestWidget(onResult: (val) => returnedName = val),
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
        expect(returnedName, isNull);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
      'shows error when mode name already exists (case-insensitive)',
      (tester) async {
        final container = ProviderContainer(
          overrides: [keyValueRepositoryProvider.overrideWithValue(mockRepo)],
        );

        await container
            .read(filterModesProvider.notifier)
            .createMode(name: 'Work', filter: const TaskFilter());

        String? returnedName;
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            onResult: (val) => returnedName = val,
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
        expect(returnedName, isNull);
      },
    );

    testWidgets('submits successfully when mode name is valid and unique', (
      tester,
    ) async {
      String? returnedName;
      await tester.pumpWidget(
        buildTestWidget(onResult: (val) => returnedName = val),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Free Time  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SaveModeDialog), findsNothing);
      expect(returnedName, 'Free Time');
    });
  });
}
