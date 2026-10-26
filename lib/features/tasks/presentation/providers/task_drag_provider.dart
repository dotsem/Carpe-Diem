import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDragState {
  final String? draggedTaskId;
  final bool hasValidTarget;
  final Object? activeScopeId;

  const TaskDragState({
    this.draggedTaskId,
    this.hasValidTarget = false,
    this.activeScopeId,
  });

  TaskDragState copyWith({
    String? Function()? draggedTaskId,
    bool? hasValidTarget,
    Object? Function()? activeScopeId,
  }) {
    return TaskDragState(
      draggedTaskId: draggedTaskId != null
          ? draggedTaskId()
          : this.draggedTaskId,
      hasValidTarget: hasValidTarget ?? this.hasValidTarget,
      activeScopeId: activeScopeId != null
          ? activeScopeId()
          : this.activeScopeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDragState &&
          runtimeType == other.runtimeType &&
          draggedTaskId == other.draggedTaskId &&
          hasValidTarget == other.hasValidTarget &&
          activeScopeId == other.activeScopeId;

  @override
  int get hashCode => Object.hash(draggedTaskId, hasValidTarget, activeScopeId);
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

  void setActiveScope(Object scopeId) {
    if (state.activeScopeId != scopeId) {
      state = state.copyWith(activeScopeId: () => scopeId);
    }
  }

  void clearActiveScope(Object scopeId) {
    if (state.activeScopeId == scopeId) {
      state = state.copyWith(activeScopeId: () => null);
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
