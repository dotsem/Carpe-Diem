import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_placeholder.dart';

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

class TaskDropZoneWrapper extends StatelessWidget {
  final int index;
  final Widget child;
  final void Function(Task task, int newIndex) onDrop;
  final bool Function(Task)? canAccept;
  final void Function(bool)? onHover;

  const TaskDropZoneWrapper({
    super.key,
    required this.index,
    required this.child,
    required this.onDrop,
    this.canAccept,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final scope = TaskDropZoneScope.of(context);

    if (scope == null) {
      return _buildStandaloneTarget(context);
    }

    return ValueListenableBuilder<TaskDropState?>(
      valueListenable: scope.activeDropNotifier,
      builder: (context, activeDrop, _) {
        final showTop =
            activeDrop != null &&
            activeDrop.index == index &&
            scope.isPositionValid(activeDrop.task, index) &&
            !scope.isPositionUnchanged(activeDrop.task, index);
        final showBottom =
            activeDrop != null &&
            activeDrop.index == index + 1 &&
            scope.isPositionValid(activeDrop.task, index + 1) &&
            !scope.isPositionUnchanged(activeDrop.task, index + 1) &&
            (index == scope.itemCount - 1 ||
                scope.isLastChildInGroup(activeDrop.task, index));

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTop)
              _buildDragSlot(
                scope: scope,
                targetIndex: index,
                placeholder: TaskCardPlaceholder(task: activeDrop.task),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                Positioned.fill(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildDragSlot(scope: scope, targetIndex: index),
                      ),
                      Expanded(
                        child: _buildDragSlot(
                          scope: scope,
                          targetIndex: index + 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showBottom)
              _buildDragSlot(
                scope: scope,
                targetIndex: index + 1,
                placeholder: TaskCardPlaceholder(task: activeDrop.task),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDragSlot({
    required TaskDropZoneScopeInherited scope,
    required int targetIndex,
    Widget? placeholder,
  }) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final effectiveIndex = scope.resolveEffectiveIndex(
          details.data,
          targetIndex,
        );
        if (!scope.isPositionValid(details.data, effectiveIndex)) {
          return false;
        }
        if (canAccept != null && !canAccept!(details.data)) {
          return false;
        }
        onHover?.call(true);
        scope.activeDropNotifier.value = TaskDropState(
          index: effectiveIndex,
          task: details.data,
        );
        return true;
      },
      onLeave: (details) {
        onHover?.call(false);
        if (scope.activeDropNotifier.value?.index == targetIndex) {
          scope.activeDropNotifier.value = null;
        }
      },
      onAcceptWithDetails: (details) {
        onHover?.call(false);
        final targetIndexResolved = scope.resolveEffectiveIndex(
          details.data,
          targetIndex,
        );
        scope.activeDropNotifier.value = null;
        if (scope.isPositionValid(details.data, targetIndexResolved)) {
          onDrop(details.data, targetIndexResolved);
        }
      },
      builder: (context, candidateData, rejectedData) =>
          placeholder ?? const SizedBox.expand(),
    );
  }

  Widget _buildStandaloneTarget(BuildContext context) {
    Task? activeTask;
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        activeTask = details.data;
        onHover?.call(true);
        return canAccept?.call(details.data) ?? true;
      },
      onLeave: (details) {
        onHover?.call(false);
        activeTask = null;
      },
      onAcceptWithDetails: (details) {
        onHover?.call(false);
        onDrop(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final task = candidateData.isNotEmpty
            ? candidateData.first
            : activeTask;
        if (task != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskCardPlaceholder(task: task),
              child,
            ],
          );
        }
        return child;
      },
    );
  }
}
