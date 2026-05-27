import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskTimerState {
  final Map<String, DateTime> pendingCompletions;

  const TaskTimerState({this.pendingCompletions = const {}});
}

class TaskTimerNotifier extends Notifier<TaskTimerState> {
  final Map<String, Timer> _completionTimers = {};

  @override
  TaskTimerState build() {
    ref.onDispose(() {
      for (final timer in _completionTimers.values) {
        timer.cancel();
      }
    });
    return const TaskTimerState();
  }

  bool isTaskPending(String taskId) => state.pendingCompletions.containsKey(taskId);

  double getPendingProgress(String taskId, int delaySeconds) {
    final startTime = state.pendingCompletions[taskId];
    if (startTime == null) return 0.0;
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final total = delaySeconds * 1000;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  void startPending(String taskId, int delaySeconds, Future<void> Function() onComplete) {
    final newPending = Map<String, DateTime>.from(state.pendingCompletions);
    newPending[taskId] = DateTime.now();
    state = TaskTimerState(pendingCompletions: newPending);

    _completionTimers[taskId] = Timer(Duration(seconds: delaySeconds), () async {
      cancelPending(taskId);
      await onComplete();
    });
  }

  void cancelPending(String taskId) {
    _completionTimers[taskId]?.cancel();
    _completionTimers.remove(taskId);
    final newPending = Map<String, DateTime>.from(state.pendingCompletions);
    newPending.remove(taskId);
    state = TaskTimerState(pendingCompletions: newPending);
  }
}

final taskTimerProvider = NotifierProvider<TaskTimerNotifier, TaskTimerState>(() {
  return TaskTimerNotifier();
});
