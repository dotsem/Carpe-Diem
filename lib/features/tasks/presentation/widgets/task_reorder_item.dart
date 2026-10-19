import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';

class TaskReorderItem extends StatelessWidget {
  final int index;
  final Widget child;
  final bool Function(Task)? canAccept;

  const TaskReorderItem({
    super.key,
    required this.index,
    required this.child,
    this.canAccept,
  });

  int _resolveRawIndex(
    BuildContext context,
    Offset globalOffset,
    Offset? pointerOffset,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final targetOffset = pointerOffset ?? globalOffset;
      final localY = box.globalToLocal(targetOffset).dy;
      if (localY >= box.size.height) return index + 1;
      return localY < (box.size.height / 2) ? index : index + 1;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    final scope = TaskReorderScope.of(context);
    if (scope == null) return child;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        if (canAccept != null && !canAccept!(details.data)) {
          return false;
        }
        final rawIndex = _resolveRawIndex(
          context,
          details.offset,
          scope.pointerOffset,
        );
        scope.onHoverSlot(details.data, rawIndex);
        return true;
      },
      onMove: (details) {
        final rawIndex = _resolveRawIndex(
          context,
          details.offset,
          scope.pointerOffset,
        );
        scope.onHoverSlot(details.data, rawIndex);
      },
      onLeave: (_) {
        scope.onLeaveSlot();
      },
      onAcceptWithDetails: (details) {
        final rawIndex = _resolveRawIndex(
          context,
          details.offset,
          scope.pointerOffset,
        );
        scope.drop(details.data, rawIndex);
      },
      builder: (context, _, _) => child,
    );
  }
}

class TaskReorderPlaceholderItem extends StatelessWidget {
  final int slotIndex;
  final Task task;

  const TaskReorderPlaceholderItem({
    super.key,
    required this.slotIndex,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final scope = TaskReorderScope.of(context);
    if (scope == null) return TaskCardPlaceholder(task: task);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        scope.onHoverSlot(details.data, slotIndex);
        return true;
      },
      onMove: (details) {
        scope.onHoverSlot(details.data, slotIndex);
      },
      onLeave: (_) {
        scope.onLeaveSlot();
      },
      onAcceptWithDetails: (details) {
        scope.drop(details.data, slotIndex);
      },
      builder: (context, _, _) => TaskCardPlaceholder(task: task),
    );
  }
}

class TaskReorderListSlot {
  final int totalCount;
  final int? placeholderIndex;
  final Task? task;

  const TaskReorderListSlot({
    required this.totalCount,
    this.placeholderIndex,
    this.task,
  });

  factory TaskReorderListSlot.from({
    required int itemCount,
    required TaskReorderActiveDrop? activeDrop,
    bool isDragging = true,
  }) {
    final showPlaceholder =
        isDragging &&
        activeDrop != null &&
        activeDrop.slot.isValid &&
        !activeDrop.slot.isUnchanged;
    final placeholderIndex = showPlaceholder ? activeDrop.slot.index : null;
    return TaskReorderListSlot(
      totalCount: itemCount + (showPlaceholder ? 1 : 0),
      placeholderIndex: placeholderIndex,
      task: showPlaceholder ? activeDrop.task : null,
    );
  }

  bool isPlaceholder(int index) =>
      placeholderIndex != null && index == placeholderIndex;

  int toOriginalIndex(int index) {
    if (placeholderIndex != null && index > placeholderIndex!) {
      return index - 1;
    }
    return index;
  }
}
