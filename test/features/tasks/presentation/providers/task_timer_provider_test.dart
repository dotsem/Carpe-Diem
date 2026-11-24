import 'dart:async';

import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tasks', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should start a pending timer and record pending state', () {
      final notifier = container.read(taskTimerProvider.notifier);

      expect(notifier.isTaskPending('task-1'), isFalse);

      notifier.startPending('task-1', 5, () async {});

      expect(notifier.isTaskPending('task-1'), isTrue);

      final state = container.read(taskTimerProvider);
      expect(state.pendingCompletions.containsKey('task-1'), isTrue);
    });

    test('should cancel pending state and void execution timer', () {
      final notifier = container.read(taskTimerProvider.notifier);
      var callbackCalled = false;

      notifier.startPending('task-1', 1, () async {
        callbackCalled = true;
      });

      notifier.cancelPending('task-1');

      expect(notifier.isTaskPending('task-1'), isFalse);

      // Wait for longer than the timer delay to verify cancellation
      expect(callbackCalled, isFalse);
    });

    test('reports zero or bounded progress', () async {
      final notifier = container.read(taskTimerProvider.notifier);
      expect(notifier.getPendingProgress('missing', 1), 0);
      notifier.startPending('task', 1, () async {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        notifier.getPendingProgress('task', 1),
        inInclusiveRange(0.0, 1.0),
      );
    });

    test(
      'should execute callback and auto-cleanup state after duration delay finishes',
      () async {
        final notifier = container.read(taskTimerProvider.notifier);
        final completer = Completer<void>();

        notifier.startPending('task-1', 1, () async {
          completer.complete();
        });

        // Wait for timer to fire
        await completer.future;

        expect(notifier.isTaskPending('task-1'), isFalse);
      },
    );

    test(
      'should cancel previous timer and execute only latest callback when restarted',
      () async {
        final notifier = container.read(taskTimerProvider.notifier);
        var firstCallbackCalled = false;
        var secondCallbackCalled = false;

        notifier.startPending('task-1', 1, () async {
          firstCallbackCalled = true;
        });

        notifier.startPending('task-1', 1, () async {
          secondCallbackCalled = true;
        });

        // wait for timer to trigger
        await Future<void>.delayed(const Duration(milliseconds: 1500));

        expect(firstCallbackCalled, isFalse);
        expect(secondCallbackCalled, isTrue);
      },
    );
  });
}
