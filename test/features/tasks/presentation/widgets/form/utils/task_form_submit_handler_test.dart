import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/utils/task_form_submit_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('TaskFormSubmitHandler placement', () {
    late TestTaskRepositories repos;

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
    });

    Widget buildTestHarness(
      void Function(BuildContext context, WidgetRef ref) onReady,
    ) {
      return ProviderScope(
        overrides: repos.providerOverrides,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onReady(context, ref);
                });
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
      'editing existing non-urgent task with null placement retains sortOrder',
      (tester) async {
        final existingTask = createTestTask(
          id: 't1',
          title: 'Normal Task',
          sortOrder: '0|h00000:',
        );
        when(
          () => repos.mockTaskRepo.getById('t1'),
        ).thenAnswer((_) async => existingTask);
        when(
          () => repos.mockTaskRepo.update(any()),
        ).thenAnswer((_) async => {});

        late BuildContext capturedContext;
        late WidgetRef capturedRef;
        await tester.pumpWidget(
          buildTestHarness((context, ref) {
            capturedContext = context;
            capturedRef = ref;
          }),
        );
        await tester.pumpAndSettle();

        final result = await TaskFormSubmitHandler.submit(
          context: capturedContext,
          ref: capturedRef,
          rawTitle: 'Updated Task',
          description: null,
          scheduledDate: null,
          deadline: null,
          blockedById: null,
          selectedProjectId: null,
          parentId: null,
          selectedLabelIds: [],
          selectedTagIds: [],
          placement: null,
          initialTask: existingTask,
        );
        await tester.pumpAndSettle();

        expect(result, isTrue);
        final captured = verify(
          () => repos.mockTaskRepo.update(captureAny()),
        ).captured;
        final updated = captured.first as Task;
        expect(updated.sortOrder, equals('0|h00000:'));
        expect(updated.isUrgent, isFalse);
      },
    );

    testWidgets(
      'editing existing urgent task with urgent placement does not reorder',
      (tester) async {
        final existingTask = createTestTask(
          id: 't_urg',
          title: 'Urgent Task',
          isUrgent: true,
          sortOrder: '0|h00000:',
        );
        when(
          () => repos.mockTaskRepo.getById('t_urg'),
        ).thenAnswer((_) async => existingTask);
        when(
          () => repos.mockTaskRepo.update(any()),
        ).thenAnswer((_) async => {});

        late BuildContext capturedContext;
        late WidgetRef capturedRef;
        await tester.pumpWidget(
          buildTestHarness((context, ref) {
            capturedContext = context;
            capturedRef = ref;
          }),
        );
        await tester.pumpAndSettle();

        final result = await TaskFormSubmitHandler.submit(
          context: capturedContext,
          ref: capturedRef,
          rawTitle: 'Updated Urgent Task',
          description: null,
          scheduledDate: null,
          deadline: null,
          blockedById: null,
          selectedProjectId: null,
          parentId: null,
          selectedLabelIds: [],
          selectedTagIds: [],
          placement: TaskPlacement.urgent,
          initialTask: existingTask,
        );
        await tester.pumpAndSettle();

        expect(result, isTrue);
        final captured = verify(
          () => repos.mockTaskRepo.update(captureAny()),
        ).captured;
        final updated = captured.first as Task;
        expect(updated.sortOrder, equals('0|h00000:'));
        expect(updated.isUrgent, isTrue);
      },
    );

    testWidgets(
      'deselecting urgent on existing urgent task sets isUrgent false without reordering',
      (tester) async {
        final existingTask = createTestTask(
          id: 't_urg',
          title: 'Urgent Task',
          isUrgent: true,
          sortOrder: '0|h00000:',
        );
        when(
          () => repos.mockTaskRepo.getById('t_urg'),
        ).thenAnswer((_) async => existingTask);
        when(
          () => repos.mockTaskRepo.update(any()),
        ).thenAnswer((_) async => {});

        late BuildContext capturedContext;
        late WidgetRef capturedRef;
        await tester.pumpWidget(
          buildTestHarness((context, ref) {
            capturedContext = context;
            capturedRef = ref;
          }),
        );
        await tester.pumpAndSettle();

        final result = await TaskFormSubmitHandler.submit(
          context: capturedContext,
          ref: capturedRef,
          rawTitle: 'No Longer Urgent',
          description: null,
          scheduledDate: null,
          deadline: null,
          blockedById: null,
          selectedProjectId: null,
          parentId: null,
          selectedLabelIds: [],
          selectedTagIds: [],
          placement: null,
          initialTask: existingTask,
        );
        await tester.pumpAndSettle();

        expect(result, isTrue);
        final captured = verify(
          () => repos.mockTaskRepo.update(captureAny()),
        ).captured;
        final updated = captured.first as Task;
        expect(updated.sortOrder, equals('0|h00000:'));
        expect(updated.isUrgent, isFalse);
      },
    );

    testWidgets('creating new task with null placement defaults to bottom', (
      tester,
    ) async {
      when(() => repos.mockTaskRepo.insert(any())).thenAnswer((_) async => {});

      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildTestHarness((context, ref) {
          capturedContext = context;
          capturedRef = ref;
        }),
      );
      await tester.pumpAndSettle();

      final result = await TaskFormSubmitHandler.submit(
        context: capturedContext,
        ref: capturedRef,
        rawTitle: 'Brand New Task',
        description: null,
        scheduledDate: null,
        deadline: null,
        blockedById: null,
        selectedProjectId: null,
        parentId: null,
        selectedLabelIds: [],
        selectedTagIds: [],
        placement: null,
        initialTask: null,
      );
      await tester.pumpAndSettle();

      expect(result, isTrue);
      final captured = verify(
        () => repos.mockTaskRepo.insert(captureAny()),
      ).captured;
      final inserted = captured.first as Task;
      expect(inserted.isUrgent, isFalse);
    });
  });
}
