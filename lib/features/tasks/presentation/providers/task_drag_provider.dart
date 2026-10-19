import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDragState {
  final String? draggedTaskId;
  final bool hasValidTarget;

  const TaskDragState({this.draggedTaskId, this.hasValidTarget = false});

  TaskDragState copyWith({
    String? Function()? draggedTaskId,
    bool? hasValidTarget,
  }) {
    return TaskDragState(
      draggedTaskId: draggedTaskId != null
          ? draggedTaskId()
          : this.draggedTaskId,
      hasValidTarget: hasValidTarget ?? this.hasValidTarget,
    );
  }
}

class TaskDragNotifier extends Notifier<TaskDragState> {
  Offset? _pointerOffset;
  Offset? get pointerOffset => _pointerOffset;

  @override
  TaskDragState build() => const TaskDragState();

  void startDrag(String taskId) {
    state = TaskDragState(draggedTaskId: taskId, hasValidTarget: false);
  }

  void updatePointerOffset(Offset offset) {
    _pointerOffset = offset;
  }

  void setValidTarget(bool hasValidTarget) {
    if (state.hasValidTarget != hasValidTarget) {
      state = state.copyWith(hasValidTarget: hasValidTarget);
    }
  }

  void endDrag() {
    _pointerOffset = null;
    state = const TaskDragState();
  }
}

final taskDragProvider = NotifierProvider<TaskDragNotifier, TaskDragState>(
  TaskDragNotifier.new,
);
