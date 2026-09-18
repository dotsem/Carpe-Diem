import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('search unfocus highlight clearing', () {
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late MockLabelRepository mockLabelRepo;
    late MockHistoryRepository mockHistoryRepo;
    late MockKeyValueRepository mockSettingsRepo;
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockTagIconRepo;

    final projectA = Project(
      id: 'p1',
      name: 'Alpha Project',
      color: Colors.blue,
      createdAt: DateTime(2025, 1, 1),
    );
    final projectB = Project(
      id: 'p2',
      name: 'Beta Project',
      color: Colors.green,
      createdAt: DateTime(2025, 1, 2),
    );

    setUp(() {
      mockTaskRepo = MockTaskRepository();
      mockProjectRepo = MockProjectRepository();
      mockLabelRepo = MockLabelRepository();
      mockHistoryRepo = MockHistoryRepository();
      mockSettingsRepo = MockKeyValueRepository();
      mockTagRepo = MockTagRepository();
      mockTagIconRepo = MockTagIconRepository();

      when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});
      when(
        () => mockProjectRepo.getAll(),
      ).thenAnswer((_) async => [projectA, projectB]);
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
    });

    List<Override> buildOverrides() => [
      taskRepositoryProvider.overrideWithValue(mockTaskRepo),
      projectRepositoryProvider.overrideWithValue(mockProjectRepo),
      labelRepositoryProvider.overrideWithValue(mockLabelRepo),
      historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
      keyValueRepositoryProvider.overrideWithValue(mockSettingsRepo),
      tagRepositoryProvider.overrideWithValue(mockTagRepo),
      tagIconRepositoryProvider.overrideWithValue(mockTagIconRepo),
    ];

    testWidgets(
      'pressing escape in search clears first item highlight so moving around highlights only focused item',
      (tester) async {
        final container = ProviderContainer(overrides: buildOverrides());
        await container.read(projectProvider.notifier).loadProjects();

        final searchFocusNode = FocusNode();
        final mainFocusNode = FocusNode();
        final gridKey = GlobalKey<ProjectGridState>();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    TextField(focusNode: searchFocusNode),
                    Expanded(
                      child: ProjectGrid(
                        key: gridKey,
                        searchQuery: 'Project',
                        searchFocusNode: searchFocusNode,
                        mainFocusNode: mainFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        searchFocusNode.requestFocus();
        await tester.pumpAndSettle();

        Card cardA = tester.widget(find.widgetWithText(Card, 'Alpha Project'));
        Card cardB = tester.widget(find.widgetWithText(Card, 'Beta Project'));
        RoundedRectangleBorder shapeA = cardA.shape! as RoundedRectangleBorder;
        RoundedRectangleBorder shapeB = cardB.shape! as RoundedRectangleBorder;
        expect(shapeA.side.color, AppColors.accent);
        expect(shapeB.side.color, Colors.transparent);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        cardA = tester.widget(find.widgetWithText(Card, 'Alpha Project'));
        cardB = tester.widget(find.widgetWithText(Card, 'Beta Project'));
        shapeA = cardA.shape! as RoundedRectangleBorder;
        shapeB = cardB.shape! as RoundedRectangleBorder;

        expect(shapeA.side.color, AppColors.accent);
        expect(shapeB.side.color, Colors.transparent);

        gridKey.currentState!.moveFocus(1, 0);
        await tester.pumpAndSettle();

        cardA = tester.widget(find.widgetWithText(Card, 'Alpha Project'));
        cardB = tester.widget(find.widgetWithText(Card, 'Beta Project'));
        shapeA = cardA.shape! as RoundedRectangleBorder;
        shapeB = cardB.shape! as RoundedRectangleBorder;

        expect(shapeA.side.color, Colors.transparent);
        expect(shapeB.side.color, AppColors.accent);

        searchFocusNode.dispose();
        mainFocusNode.dispose();
      },
    );
  });
}
