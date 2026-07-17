import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_autocomplete_text_field.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('tags', () {
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockTagIconRepo;
    late TextEditingController controller;

    setUp(() {
      mockTagRepo = MockTagRepository();
      mockTagIconRepo = MockTagIconRepository();
      controller = TextEditingController();

      when(() => mockTagRepo.getAll()).thenAnswer((_) async => [
        const Tag(id: 't1', name: 'work'),
        const Tag(id: 't2', name: 'personal'),
      ]);
      when(() => mockTagIconRepo.getAllIconDatas()).thenAnswer((_) async => {});
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('shows overlay when hash symbol is typed and hides when text is cleared', (tester) async {
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
              body: TagAutocompleteTextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello ');
      await tester.pump();
      expect(find.text('#work'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Hello #w');
      await tester.pump();
      await tester.pump();

      expect(find.text('#work'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      expect(find.text('#work'), findsNothing);
    });

    testWidgets('inserts tag name on suggestion tap when keepTagsInTitle is true', (tester) async {
      final mockSettingsRepo = MockSettingsRepository();
      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {
        'keep_tags_in_title': 'true',
      });

      final container = ProviderContainer(
        overrides: [
          tagRepositoryProvider.overrideWithValue(mockTagRepo),
          tagIconRepositoryProvider.overrideWithValue(mockTagIconRepo),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );

      await container.read(tagProvider.notifier).loadTags();
      await container.read(tagIconProvider.notifier).loadIcons();
      await container.read(settingsProvider.notifier).loadSettings();

      Tag? selectedTag;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TagAutocompleteTextField(
                controller: controller,
                onTagSelected: (tag) => selectedTag = tag,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello #p');
      await tester.pump();
      await tester.pump();

      expect(find.text('#personal'), findsOneWidget);

      await tester.tap(find.text('#personal'));
      await tester.pump();

      expect(controller.text, equals('Hello #personal '));
      expect(selectedTag, isNotNull);
      expect(selectedTag!.name, equals('personal'));
    });

    testWidgets('strips tag name and returns on suggestion tap when keepTagsInTitle is false', (tester) async {
      final mockSettingsRepo = MockSettingsRepository();
      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {
        'keep_tags_in_title': 'false',
      });

      final container = ProviderContainer(
        overrides: [
          tagRepositoryProvider.overrideWithValue(mockTagRepo),
          tagIconRepositoryProvider.overrideWithValue(mockTagIconRepo),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );

      await container.read(tagProvider.notifier).loadTags();
      await container.read(tagIconProvider.notifier).loadIcons();
      await container.read(settingsProvider.notifier).loadSettings();

      Tag? selectedTag;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TagAutocompleteTextField(
                controller: controller,
                onTagSelected: (tag) => selectedTag = tag,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello #p');
      await tester.pump();
      await tester.pump();

      expect(find.text('#personal'), findsOneWidget);

      await tester.tap(find.text('#personal'));
      await tester.pump();

      expect(controller.text, equals('Hello '));
      expect(selectedTag, isNotNull);
      expect(selectedTag!.name, equals('personal'));
    });
  });
}
