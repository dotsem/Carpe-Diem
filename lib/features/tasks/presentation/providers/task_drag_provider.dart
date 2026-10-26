import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDragState {
  final String? draggedTaskId;
  final bool hasValidTarget;
  final Object? activeScopeId;
  final bool isCancelled;

  const TaskDragState({
    this.draggedTaskId,
    this.hasValidTarget = false,
    this.activeScopeId,
    this.isCancelled = false,
  });

  TaskDragState copyWith({
    String? Function()? draggedTaskId,
    bool? hasValidTarget,
    Object? Function()? activeScopeId,
    bool? isCancelled,
  }) {
    return TaskDragState(
      draggedTaskId: draggedTaskId != null
          ? draggedTaskId()
          : this.draggedTaskId,
      hasValidTarget: hasValidTarget ?? this.hasValidTarget,
      activeScopeId: activeScopeId != null
          ? activeScopeId()
          : this.activeScopeId,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDragState &&
          runtimeType == other.runtimeType &&
          draggedTaskId == other.draggedTaskId &&
          hasValidTarget == other.hasValidTarget &&
          activeScopeId == other.activeScopeId &&
          isCancelled == other.isCancelled;

  @override
  int get hashCode =>
      Object.hash(draggedTaskId, hasValidTarget, activeScopeId, isCancelled);
}

class TaskDragNotifier extends Notifier<TaskDragState> {
  Offset? _pointerOffset;
  Offset? get pointerOffset => _pointerOffset;
  bool _isListeningToPointer = false;

  @override
  TaskDragState build() {
    ref.onDispose(_removePointerListener);
    return const TaskDragState();
  }

  void _addPointerListener() {
    if (!_isListeningToPointer) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointer);
      _isListeningToPointer = true;
    }
  }

  void _removePointerListener() {
    if (_isListeningToPointer) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointer);
      _isListeningToPointer = false;
    }
  }

  void _handlePointer(PointerEvent event) {
    if ((event.buttons & kSecondaryMouseButton) != 0 &&
        state.draggedTaskId != null) {
      cancelDrag(event);
    }
  }

  void startDrag(String taskId) {
    _addPointerListener();
    state = TaskDragState(
      draggedTaskId: taskId,
      hasValidTarget: false,
      isCancelled: false,
    );
  }

  void cancelDrag([PointerEvent? event]) {
    _removePointerListener();
    if (event != null) {
      GestureBinding.instance.handlePointerEvent(
        PointerCancelEvent(
          pointer: event.pointer,
          kind: event.kind,
          device: event.device,
          position: event.position,
        ),
      );
    }
    _pointerOffset = null;
    state = state.copyWith(isCancelled: true, draggedTaskId: () => null);
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
    _removePointerListener();
    _pointerOffset = null;
    state = const TaskDragState();
  }
}

final taskDragProvider = NotifierProvider<TaskDragNotifier, TaskDragState>(
  TaskDragNotifier.new,
);
