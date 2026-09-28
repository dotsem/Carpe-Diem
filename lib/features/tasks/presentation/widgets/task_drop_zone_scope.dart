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
  final Widget child;

  const TaskDropZoneScope({
    super.key,
    required this.urgentSectionEndIndex,
    required this.itemCount,
    this.isPositionUnchanged,
    this.isPositionValid,
    this.isLastChildInGroup,
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

  const TaskDropZoneScopeInherited({
    super.key,
    required this.activeDropNotifier,
    required this.urgentSectionEndIndex,
    required this.itemCount,
    this.isPositionUnchangedCallback,
    this.isPositionValidCallback,
    this.isLastChildInGroupCallback,
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

  @override
  bool updateShouldNotify(TaskDropZoneScopeInherited oldWidget) {
    return activeDropNotifier != oldWidget.activeDropNotifier ||
        urgentSectionEndIndex != oldWidget.urgentSectionEndIndex ||
        itemCount != oldWidget.itemCount ||
        isPositionUnchangedCallback != oldWidget.isPositionUnchangedCallback ||
        isPositionValidCallback != oldWidget.isPositionValidCallback ||
        isLastChildInGroupCallback != oldWidget.isLastChildInGroupCallback;
  }
}
