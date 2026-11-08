import 'package:carpe_diem/features/tasks/data/models/task.dart';
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

  group('TaskFormSubmitHandler clearing fields on edit', () {
    late TestTaskRepositories repos;

    final existingTask = createTestTask(
      id: 't1',
      title: 'Filled Task',
      description: 'Some description',
      scheduledDate: DateTime(2026, 11, 10),
      deadline: DateTime(2026, 11, 20),
      blockedById: 'blocker',
      projectId: 'proj1',
      parentId: 'parent',
      isUrgent: true,
      labelIds: ['label1'],
      tagIds: ['tag1'],
    );

    setUp(() {
      repos = TestTaskRepositories();
      repos.setupDefaultStubs();
      when(
        () => repos.mockTaskRepo.getById('t1'),
      ).thenAnswer((_) async => existingTask);
      when(() => repos.mockTaskRepo.update(any())).thenAnswer((_) async => {});
    });

    Future<Task> submitWithEverythingCleared(WidgetTester tester) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await TaskFormSubmitHandler.submit(
        context: capturedContext,
        ref: capturedRef,
        rawTitle: 'Filled Task',
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
      return captured.whereType<Task>().firstWhere((t) => t.id == 't1');
    }

    final cases = <String, Object? Function(Task)>{
      'description': (t) => t.description ?? '',
      'scheduledDate': (t) => t.scheduledDate,
      'deadline': (t) => t.deadline,
      'blockedById': (t) => t.blockedById,
      'projectId': (t) => t.projectId,
      'parentId': (t) => t.parentId,
      'isUrgent': (t) => t.isUrgent ? true : null,
      'labelIds': (t) => t.labelIds.isEmpty ? null : t.labelIds,
      'tagIds': (t) => t.tagIds.isEmpty ? null : t.tagIds,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} can be cleared', (tester) async {
        final updated = await submitWithEverythingCleared(tester);
        final value = entry.value(updated);
        expect(value == null || value == '', isTrue, reason: '$value');
      });
    }
  });
}
