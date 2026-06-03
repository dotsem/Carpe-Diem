import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';

void main() {
  group('TaskTimerNotifier', () {
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
      bool callbackCalled = false;

      notifier.startPending('task-1', 1, () async {
        callbackCalled = true;
      });

      notifier.cancelPending('task-1');

      expect(notifier.isTaskPending('task-1'), isFalse);
      
      // Wait for longer than the timer delay to verify cancellation
      expect(callbackCalled, isFalse);
    });

    test('should execute callback and auto-cleanup state after duration delay finishes', () async {
      final notifier = container.read(taskTimerProvider.notifier);
      final completer = Completer<void>();

      notifier.startPending('task-1', 1, () async {
        completer.complete();
      });

      // Wait for timer to fire
      await completer.future;

      expect(notifier.isTaskPending('task-1'), isFalse);
    });
  });
}
