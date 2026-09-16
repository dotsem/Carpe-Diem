import 'package:carpe_diem/features/common/presentation/widgets/chip/chip.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/widgets/context_menu_helpers.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_board.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/task_test_helpers.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  final bool initialReviewState;
  _TestSettingsNotifier(this.initialReviewState);

  @override
  SettingsState build() {
    return SettingsState({
      SettingsConstants.keyReviewState: initialReviewState.toString(),
    });
  }

  @override
  Future<void> setReviewState(bool value) async {
    state = SettingsState({SettingsConstants.keyReviewState: value.toString()});
  }
}

void main() {
  group('tasks', () {
    late TestTaskRepositories repos;
    late Task reviewTask;
    late Task inProgressTask;
    late Task todoTask;
    late Task doneTask;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();

      final now = DateTime(2026, 6, 1);
      todoTask = createTestTask(
        id: 't-todo',
        title: 'Todo Task',
        status: TaskStatus.todo,
        createdAt: now,
      );
      inProgressTask = createTestTask(
        id: 't-prog',
        title: 'In Prog Task',
        status: TaskStatus.inProgress,
        createdAt: now,
      );
      reviewTask = createTestTask(
        id: 't-rev',
        title: 'Review Task',
        status: TaskStatus.review,
        createdAt: now,
      );
      doneTask = createTestTask(
        id: 't-done',
        title: 'Done Task',
        status: TaskStatus.done,
        createdAt: now,
      );
    });

    Widget buildTestWidget({
      required Widget child,
      bool reviewStateEnabled = false,
    }) {
      return ProviderScope(
        overrides: [
          ...repos.providerOverrides,
          settingsProvider.overrideWith(
            () => _TestSettingsNotifier(reviewStateEnabled),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets(
      'StatusChip displays "In Progress" when reviewState is disabled',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: StatusChip(task: reviewTask),
            reviewStateEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Review'), findsNothing);
      },
    );

    testWidgets('StatusChip displays "Review" when reviewState is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: StatusChip(task: reviewTask),
          reviewStateEnabled: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('In Progress'), findsNothing);
    });

    testWidgets(
      'TaskStatusIndicator displays rate_review icon for review tasks',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: TaskStatusIndicator(
              task: reviewTask,
              selectionMode: false,
              onToggle: (_) {},
              onToggleAction: () {},
            ),
            reviewStateEnabled: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
      },
    );

    testWidgets(
      'KanbanBoard falls back review task to In Progress column when reviewState is disabled',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final tasks = [todoTask, inProgressTask, reviewTask, doneTask];

        await tester.pumpWidget(
          buildTestWidget(
            child: KanbanBoard(
              tasks: tasks,
              onStatusChange: (_, _) {},
              onContextMenu: (_, _, _) {},
              onEdit: (_) {},
            ),
            reviewStateEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Todo'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Review'), findsNothing);
        expect(find.text('Done'), findsOneWidget);

        expect(find.text('Review Task'), findsOneWidget);
        expect(find.text('In Prog Task'), findsOneWidget);
      },
    );

    testWidgets(
      'KanbanBoard shows 4 columns and puts review task in Review column when reviewState is enabled',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final tasks = [todoTask, inProgressTask, reviewTask, doneTask];

        await tester.pumpWidget(
          buildTestWidget(
            child: KanbanBoard(
              tasks: tasks,
              onStatusChange: (_, _) {},
              onContextMenu: (_, _, _) {},
              onEdit: (_) {},
            ),
            reviewStateEnabled: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Todo'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        expect(find.text('Review Task'), findsOneWidget);
      },
    );

    testWidgets(
      'Context menu items adapt when reviewState is enabled vs disabled',
      (tester) async {
        late BuildContext testContext;
        late WidgetRef testRef;

        await tester.pumpWidget(
          buildTestWidget(
            child: Consumer(
              builder: (context, ref, _) {
                testContext = context;
                testRef = ref;
                return const SizedBox();
              },
            ),
            reviewStateEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        final disabledItems = buildProgressStateItems(
          testContext,
          testRef,
          inProgressTask,
        );
        expect(disabledItems.length, equals(2));

        await testRef.read(settingsProvider.notifier).setReviewState(true);
        await tester.pumpAndSettle();

        final enabledItems = buildProgressStateItems(
          testContext,
          testRef,
          inProgressTask,
        );
        expect(enabledItems.length, equals(3));

        final reviewItems = buildProgressStateItems(
          testContext,
          testRef,
          reviewTask,
        );
        expect(reviewItems.length, equals(3));
      },
    );
  });
}
