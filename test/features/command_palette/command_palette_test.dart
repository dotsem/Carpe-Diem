import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:carpe_diem/features/command_palette/models/palette_command.dart';
import 'package:carpe_diem/features/command_palette/presentation/widgets/command_palette.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import '../../helpers/mock_repositories.dart';

void main() {
  group('Command Palette Unit Tests', () {
    test('FuzzySearchUtils matches PaletteCommand correctly', () {
      final commands = [
        PaletteCommand(
          id: '1',
          title: 'Go to Today',
          icon: Icons.today,
          category: CommandCategory.navigation,
          onSelect: () {},
          keywords: const ['today', 'schedule'],
        ),
        PaletteCommand(
          id: '2',
          title: 'Switch to Dark Theme',
          icon: Icons.dark_mode,
          category: CommandCategory.actions,
          onSelect: () {},
          keywords: const ['theme', 'dark'],
        ),
        PaletteCommand(
          id: '3',
          title: 'Mobile Redesign Project',
          icon: Icons.folder,
          category: CommandCategory.projects,
          onSelect: () {},
          keywords: const ['project'],
        ),
      ];

      final resultsToday = FuzzySearchUtils.search<PaletteCommand>(
        query: 'today',
        items: commands,
        itemToString: (c) => c.searchableText,
      );
      expect(resultsToday.first.id, equals('1'));

      final resultsTheme = FuzzySearchUtils.search<PaletteCommand>(
        query: 'dark',
        items: commands,
        itemToString: (c) => c.searchableText,
      );
      expect(resultsTheme.first.id, equals('2'));
    });
  });

  group('CommandPaletteDialog Widget Tests', () {
    late MockKeyValueRepository mockSettingsRepo;
    late MockProjectRepository mockProjectRepo;
    late MockTaskRepository mockTaskRepo;
    late MockLabelRepository mockLabelRepo;
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockTagIconRepo;
    late MockHistoryRepository mockHistoryRepo;
    late ProviderContainer container;

    setUp(() {
      mockSettingsRepo = MockKeyValueRepository();
      mockProjectRepo = MockProjectRepository();
      mockTaskRepo = MockTaskRepository();
      mockLabelRepo = MockLabelRepository();
      mockTagRepo = MockTagRepository();
      mockTagIconRepo = MockTagIconRepository();
      mockHistoryRepo = MockHistoryRepository();

      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});
      when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockTagRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockTagIconRepo.getAllIconDatas()).thenAnswer((_) async => {});
      when(
        () => mockTaskRepo.getByDate(
          any(),
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        ),
      ).thenAnswer((_) async => []);
      when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
      when(
        () => mockTaskRepo.getUnscheduled(
          prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
        ),
      ).thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          keyValueRepositoryProvider.overrideWithValue(mockSettingsRepo),
          projectRepositoryProvider.overrideWithValue(mockProjectRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          labelRepositoryProvider.overrideWithValue(mockLabelRepo),
          tagRepositoryProvider.overrideWithValue(mockTagRepo),
          tagIconRepositoryProvider.overrideWithValue(mockTagIconRepo),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
          undoRedoProvider.overrideWith(() => UndoRedoNotifier()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: CommandPalette())),
      );
    }

    testWidgets('renders search input and commands list', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Go to Today'), findsOneWidget);
      expect(find.text('Go to Backlog'), findsOneWidget);
      expect(find.text('ESC'), findsOneWidget);
    });

    testWidgets('filters commands when typing in search input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'settings');
      await tester.pumpAndSettle();

      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.text('Go to Today'), findsNothing);
    });

    testWidgets('keyboard down arrow navigates commands and enter selects', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(find.byType(CommandPalette), findsOneWidget);
    });

    testWidgets('Escape key closes dialog', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CommandPalette.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CommandPalette), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CommandPalette), findsNothing);
    });

    testWidgets('CommandPalette.show opens using rootNavigatorKey', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: rootNavigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );

      CommandPalette.show();
      await tester.pumpAndSettle();
      expect(find.byType(CommandPalette), findsOneWidget);
    });
  });
}
