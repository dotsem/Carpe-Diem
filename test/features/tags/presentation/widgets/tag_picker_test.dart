import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_picker.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('tags', () {
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockTagIconRepo;

    setUp(() {
      mockTagRepo = MockTagRepository();
      mockTagIconRepo = MockTagIconRepository();
      
      when(() => mockTagRepo.getAll()).thenAnswer((_) async => [
        const Tag(id: 't1', name: 'work'),
        const Tag(id: 't2', name: 'personal'),
      ]);
      when(() => mockTagIconRepo.getAllIconDatas()).thenAnswer((_) async => {});
    });

    testWidgets('renders tags as FilterChips and adds to selected list on tap', (tester) async {
      List<String>? selectedIds;

      final container = ProviderContainer(
        overrides: [
          tagRepositoryProvider.overrideWithValue(mockTagRepo),
          tagIconRepositoryProvider.overrideWithValue(mockTagIconRepo),
        ],
      );

      await container.read(tagProvider.notifier).loadTags();
      await container.read(tagIconProvider.notifier).loadIcons();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TagPicker(
                selectedTagIds: const ['t1'],
                onSelected: (ids) {
                  selectedIds = ids;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('work'), findsOneWidget);
      expect(find.text('personal'), findsOneWidget);
      expect(find.text('New Tag'), findsOneWidget);

      final FilterChip workChip = tester.widget(
        find.ancestor(of: find.text('work'), matching: find.byType(FilterChip)),
      );
      expect(workChip.selected, isTrue);

      final FilterChip personalChip = tester.widget(
        find.ancestor(of: find.text('personal'), matching: find.byType(FilterChip)),
      );
      expect(personalChip.selected, isFalse);

      await tester.tap(find.text('personal'));
      await tester.pump();

      expect(selectedIds, equals(['t1', 't2']));
    });
  });
}
