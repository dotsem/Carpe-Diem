import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';

class TaskReorderListSlot {
  final int totalCount;
  final int? placeholderIndex;
  final Task? task;
  final int? draggedIndex;

  const TaskReorderListSlot({
    required this.totalCount,
    this.placeholderIndex,
    this.task,
    this.draggedIndex,
  });

  factory TaskReorderListSlot.forNodes({
    required List<TaskHierarchyNode> nodes,
    required TaskReorderActiveDrop? activeDrop,
    required String? draggedTaskId,
  }) {
    final draggedIndex = draggedTaskId != null
        ? nodes.indexWhere((n) => n.task?.id == draggedTaskId)
        : null;
    return TaskReorderListSlot.from(
      itemCount: nodes.length,
      activeDrop: activeDrop,
      isDragging: draggedTaskId != null,
      draggedIndex: draggedIndex != null && draggedIndex >= 0
          ? draggedIndex
          : null,
    );
  }

  factory TaskReorderListSlot.from({
    required int itemCount,
    required TaskReorderActiveDrop? activeDrop,
    bool isDragging = true,
    int? draggedIndex,
  }) {
    if (!isDragging) {
      return TaskReorderListSlot(totalCount: itemCount);
    }

    if (draggedIndex != null && draggedIndex >= 0 && draggedIndex < itemCount) {
      if (activeDrop != null && activeDrop.slot.isValid) {
        int gapIndex = draggedIndex;
        if (!activeDrop.slot.isUnchanged) {
          final raw = activeDrop.slot.index;
          gapIndex = (raw > draggedIndex ? raw - 1 : raw).clamp(
            0,
            itemCount - 1,
          );
        }
        return TaskReorderListSlot(
          totalCount: itemCount,
          placeholderIndex: gapIndex,
          task: activeDrop.task,
          draggedIndex: draggedIndex,
        );
      }
      return TaskReorderListSlot(
        totalCount: (itemCount - 1).clamp(0, itemCount),
        placeholderIndex: null,
        draggedIndex: draggedIndex,
      );
    }

    final showPlaceholder =
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
    if (placeholderIndex == null) {
      if (draggedIndex != null && draggedIndex! >= 0) {
        return index >= draggedIndex! ? index + 1 : index;
      }
      return index;
    }
    if (draggedIndex != null && draggedIndex! >= 0) {
      final r = index > placeholderIndex! ? index - 1 : index;
      return r >= draggedIndex! ? r + 1 : r;
    }
    return index > placeholderIndex! ? index - 1 : index;
  }

  int? findChildIndex(
    Key key, {
    required String prefix,
    required List<TaskHierarchyNode> nodes,
  }) {
    if (key is! ValueKey<String>) return null;
    if (key.value == 'drag_placeholder_gap') return placeholderIndex;
    final id = key.value.replaceFirst(prefix, '');
    for (int i = 0; i < totalCount; i++) {
      if (!isPlaceholder(i)) {
        final a = toOriginalIndex(i);
        if (a < nodes.length && nodes[a].task?.id == id) return i;
      }
    }
    return null;
  }
}
