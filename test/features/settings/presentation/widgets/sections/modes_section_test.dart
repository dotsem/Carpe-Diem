import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/sections/filtering_and_modes_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mock_repositories.dart';

void main() {
  group('modes_section', () {
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

    Widget buildTestWidget({ProviderContainer? container}) {
      return UncontrolledProviderScope(
        container:
            container ??
            ProviderContainer(
              overrides: [
                keyValueRepositoryProvider.overrideWithValue(mockRepo),
              ],
            ),
        child: const MaterialApp(home: Scaffold(body: ModesSection())),
      );
    }

    testWidgets('shows empty placeholder when no modes exist', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No filter modes created yet.'), findsOneWidget);
      expect(find.text('Create Mode'), findsOneWidget);
    });

    testWidgets('renders list of saved modes with filter summaries', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [keyValueRepositoryProvider.overrideWithValue(mockRepo)],
      );

      await container
          .read(filterModesProvider.notifier)
          .createMode(
            name: 'Study',
            filter: const TaskFilter(
              isUrgent: true,
              projectIdsIncluded: {'p1'},
            ),
          );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Urgent only • 1 project(s)'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('New Mode'), findsOneWidget);
    });
  });
}
