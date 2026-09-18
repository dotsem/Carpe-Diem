import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_card.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('search highlighting', () {
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late MockLabelRepository mockLabelRepo;
    late MockHistoryRepository mockHistoryRepo;
    late MockKeyValueRepository mockSettingsRepo;
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockTagIconRepo;

    setUp(() {
      mockTaskRepo = MockTaskRepository();
      mockProjectRepo = MockProjectRepository();
      mockLabelRepo = MockLabelRepository();
      mockHistoryRepo = MockHistoryRepository();
      mockSettingsRepo = MockKeyValueRepository();
      mockTagRepo = MockTagRepository();
      mockTagIconRepo = MockTagIconRepository();

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
      'ProjectCard focus highlight is driven strictly by its FocusNode',
      (tester) async {
        final focusNodeA = FocusNode();
        final focusNodeB = FocusNode();
        final projectA = Project(
          id: 'p1',
          name: 'Alpha',
          color: Colors.blue,
          createdAt: DateTime.now(),
        );
        final projectB = Project(
          id: 'p2',
          name: 'Beta',
          color: Colors.green,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ProjectCard(
                      key: const ValueKey('card_p1'),
                      project: projectA,
                      focusNode: focusNodeA,
                    ),
                    ProjectCard(
                      key: const ValueKey('card_p2'),
                      project: projectB,
                      focusNode: focusNodeB,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        focusNodeA.requestFocus();
        await tester.pumpAndSettle();

        Card cardA = tester.widget(find.widgetWithText(Card, 'Alpha'));
        Card cardB = tester.widget(find.widgetWithText(Card, 'Beta'));
        RoundedRectangleBorder shapeA = cardA.shape! as RoundedRectangleBorder;
        RoundedRectangleBorder shapeB = cardB.shape! as RoundedRectangleBorder;

        expect(shapeA.side.color, AppColors.accent);
        expect(shapeA.side.width, 2);
        expect(shapeB.side.color, Colors.transparent);

        focusNodeB.requestFocus();
        await tester.pumpAndSettle();

        cardA = tester.widget(find.widgetWithText(Card, 'Alpha'));
        cardB = tester.widget(find.widgetWithText(Card, 'Beta'));
        shapeA = cardA.shape! as RoundedRectangleBorder;
        shapeB = cardB.shape! as RoundedRectangleBorder;

        expect(shapeA.side.color, Colors.transparent);
        expect(shapeB.side.color, AppColors.accent);
        expect(shapeB.side.width, 2);

        focusNodeA.dispose();
        focusNodeB.dispose();
      },
    );

    testWidgets(
      'TaskListView allocates distinct focus nodes and avoids aliasing across search reordering',
      (tester) async {
        final taskUrgent = Task(
          id: 't-urgent',
          title: 'Urgent Task',
          status: TaskStatus.todo,
          isUrgent: true,
          createdAt: DateTime.now(),
        );
        final taskMatching = Task(
          id: 't-match',
          title: 'Apples and Oranges',
          status: TaskStatus.todo,
          isUrgent: false,
          createdAt: DateTime.now(),
        );

        final itemFocusNodes = <String, FocusNode>{};
        final orderedIds = <String>[];

        Widget buildView(String? query) {
          return ProviderScope(
            overrides: buildOverrides(),
            child: MaterialApp(
              home: Scaffold(
                body: TaskListView(
                  tasks: [taskUrgent, taskMatching],
                  searchQuery: query,
                  itemFocusNodes: itemFocusNodes,
                  onOrderedIdsChanged: (ids) {
                    orderedIds
                      ..clear()
                      ..addAll(ids);
                  },
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildView(null));
        await tester.pumpAndSettle();

        expect(orderedIds.first, 't-urgent');
        expect(itemFocusNodes['t-urgent'], isNotNull);

        await tester.pumpWidget(buildView('Apples'));
        await tester.pumpAndSettle();

        expect(orderedIds.first, 't-match');
        expect(itemFocusNodes['t-match'], isNotNull);
        expect(itemFocusNodes['t-urgent'], isNotNull);
        expect(
          identical(itemFocusNodes['t-match'], itemFocusNodes['t-urgent']),
          isFalse,
        );

        itemFocusNodes['t-match']!.requestFocus();
        await tester.pumpAndSettle();

        expect(itemFocusNodes['t-match']!.hasFocus, isTrue);
        expect(itemFocusNodes['t-urgent']!.hasFocus, isFalse);

        for (final n in itemFocusNodes.values) {
          n.dispose();
        }
      },
    );
  });
}
