import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class TaskDropState {
  final int index;
  final Task task;

  const TaskDropState({required this.index, required this.task});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDropState &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          task.id == other.task.id;

  @override
  int get hashCode => index.hashCode ^ task.id.hashCode;
}

class TaskDropZoneScope extends StatefulWidget {
  final int urgentSectionEndIndex;
  final int itemCount;
  final bool Function(Task task, int targetIndex)? isPositionUnchanged;
  final bool Function(Task task, int targetIndex)? isPositionValid;
  final bool Function(Task task, int index)? isLastChildInGroup;
  final int Function(Task task)? resolveClampedTopIndex;
  final int Function(Task task)? resolveClampedBottomIndex;
  final void Function(Task task, int targetIndex)? onDrop;
  final Widget child;

  const TaskDropZoneScope({
    super.key,
    required this.urgentSectionEndIndex,
    required this.itemCount,
    this.isPositionUnchanged,
    this.isPositionValid,
    this.isLastChildInGroup,
    this.resolveClampedTopIndex,
    this.resolveClampedBottomIndex,
    this.onDrop,
    required this.child,
  });

  static TaskDropZoneScopeInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TaskDropZoneScopeInherited>();
  }

  @override
  State<TaskDropZoneScope> createState() => _TaskDropZoneScopeState();
}

class _TaskDropZoneScopeState extends State<TaskDropZoneScope> {
  final ValueNotifier<TaskDropState?> _activeDrop =
      ValueNotifier<TaskDropState?>(null);

  @override
  void dispose() {
    _activeDrop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TaskDropZoneScopeInherited(
      activeDropNotifier: _activeDrop,
      urgentSectionEndIndex: widget.urgentSectionEndIndex,
      itemCount: widget.itemCount,
      isPositionUnchangedCallback: widget.isPositionUnchanged,
      isPositionValidCallback: widget.isPositionValid,
      isLastChildInGroupCallback: widget.isLastChildInGroup,
      resolveClampedTopIndexCallback: widget.resolveClampedTopIndex,
      resolveClampedBottomIndexCallback: widget.resolveClampedBottomIndex,
      onDropCallback: widget.onDrop,
      child: widget.child,
    );
  }
}

class TaskDropZoneScopeInherited extends InheritedWidget {
  final ValueNotifier<TaskDropState?> activeDropNotifier;
  final int urgentSectionEndIndex;
  final int itemCount;
  final bool Function(Task task, int targetIndex)? isPositionUnchangedCallback;
  final bool Function(Task task, int targetIndex)? isPositionValidCallback;
  final bool Function(Task task, int index)? isLastChildInGroupCallback;
  final int Function(Task task)? resolveClampedTopIndexCallback;
  final int Function(Task task)? resolveClampedBottomIndexCallback;
  final void Function(Task task, int targetIndex)? onDropCallback;

  const TaskDropZoneScopeInherited({
    super.key,
    required this.activeDropNotifier,
    required this.urgentSectionEndIndex,
    required this.itemCount,
    this.isPositionUnchangedCallback,
    this.isPositionValidCallback,
    this.isLastChildInGroupCallback,
    this.resolveClampedTopIndexCallback,
    this.resolveClampedBottomIndexCallback,
    this.onDropCallback,
    required super.child,
  });

  bool isPositionUnchanged(Task task, int targetIndex) {
    return isPositionUnchangedCallback?.call(task, targetIndex) ?? false;
  }

  bool isPositionValid(Task task, int targetIndex) {
    return isPositionValidCallback?.call(task, targetIndex) ?? true;
  }

  bool isLastChildInGroup(Task task, int index) {
    return isLastChildInGroupCallback?.call(task, index) ?? false;
  }

  int resolveEffectiveIndex(Task task, int rawIndex) {
    if (!task.isUrgent) {
      if (rawIndex < urgentSectionEndIndex) {
        return urgentSectionEndIndex;
      }
    } else {
      if (rawIndex > urgentSectionEndIndex) {
        return urgentSectionEndIndex;
      }
    }
    return rawIndex;
  }

  int resolveClampedTopIndex(Task task) {
    return resolveClampedTopIndexCallback?.call(task) ?? 0;
  }

  int resolveClampedBottomIndex(Task task) {
    return resolveClampedBottomIndexCallback?.call(task) ?? itemCount;
  }

  void drop(Task task, int targetIndex) {
    onDropCallback?.call(task, targetIndex);
  }

  @override
  bool updateShouldNotify(TaskDropZoneScopeInherited oldWidget) {
    return activeDropNotifier != oldWidget.activeDropNotifier ||
        urgentSectionEndIndex != oldWidget.urgentSectionEndIndex ||
        itemCount != oldWidget.itemCount ||
        isPositionUnchangedCallback != oldWidget.isPositionUnchangedCallback ||
        isPositionValidCallback != oldWidget.isPositionValidCallback ||
        isLastChildInGroupCallback != oldWidget.isLastChildInGroupCallback ||
        resolveClampedTopIndexCallback !=
            oldWidget.resolveClampedTopIndexCallback ||
        resolveClampedBottomIndexCallback !=
            oldWidget.resolveClampedBottomIndexCallback ||
        onDropCallback != oldWidget.onDropCallback;
  }
}
