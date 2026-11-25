import 'dart:async';
import 'dart:ui';

import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/main.dart' as app;
import 'package:carpe_diem/routes/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toastification/toastification.dart';

import 'helpers/task_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('global error handling', () {
    testWidgets('shows a toast for an unawaited task update failure', (
      tester,
    ) async {
      final previousFlutterHandler = FlutterError.onError;
      final previousPlatformHandler = PlatformDispatcher.instance.onError;
      addTearDown(() {
        FlutterError.onError = previousFlutterHandler;
        PlatformDispatcher.instance.onError = previousPlatformHandler;
        toastification.dismissAll(delayForAnimation: false);
      });

      final repos = TestTaskRepositories();
      repos.setupDefaultStubs();
      final task = createTestTask();
      when(
        () => repos.mockTaskRepo.getById(task.id),
      ).thenAnswer((_) async => task);
      when(
        () => repos.mockTaskRepo.update(any()),
      ).thenThrow(StateError('write failed'));

      app.installErrorHandlers();
      await tester.pumpWidget(
        ProviderScope(
          overrides: repos.providerOverrides,
          child: ToastificationWrapper(
            child: MaterialApp(
              navigatorKey: rootNavigatorKey,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => TextButton(
                    // why: test zones catch async errors; real engine events run in the root zone
                    onPressed: () => Zone.root.run(
                      () => unawaited(
                        ref.read(taskProvider.notifier).updateTask(task),
                      ),
                    ),
                    child: const Text('Update'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Update'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));

      final manager = toastification.managers[Alignment.bottomRight];
      expect(manager?.notifications, hasLength(1));
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
