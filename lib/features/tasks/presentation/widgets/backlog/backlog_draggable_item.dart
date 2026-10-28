import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_hierarchy_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_platform_draggable.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BacklogDraggableItem extends ConsumerWidget {
  final TaskHierarchyNode node;
  final int index;
  final List<Task> allTasks;
  final List<String> selectedTaskIds;
  final String? highlightedTaskId;
  final Map<String, FocusNode> itemFocusNodes;
  final ValueChanged<Task> onSelectedChanged;
  final ValueChanged<Task> onEdit;
  final Widget Function(BuildContext, Task)? trailingBuilder;
  final double maxWidth;
  final int? visualIndex;

  const BacklogDraggableItem({
    super.key,
    required this.node,
    required this.index,
    required this.allTasks,
    required this.selectedTaskIds,
    required this.highlightedTaskId,
    required this.itemFocusNodes,
    required this.onSelectedChanged,
    required this.onEdit,
    this.trailingBuilder,
    required this.maxWidth,
    this.visualIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = BacklogHierarchyItem(
      node: node,
      allTasks: allTasks,
      selectedTaskIds: selectedTaskIds,
      highlightedTaskId: highlightedTaskId,
      itemFocusNodes: itemFocusNodes,
      onSelectedChanged: onSelectedChanged,
      onEdit: onEdit,
      trailingBuilder: trailingBuilder,
    );

    Widget draggableChild = child;
    final task = node.task;
    if (task != null) {
      final isSelected = selectedTaskIds.contains(task.id);

      draggableChild = TaskPlatformDraggable(
        task: task,
        feedbackWidth: maxWidth - 32,
        selectedCount: isSelected ? selectedTaskIds.length : 1,
        child: child,
      );
    }

    return TaskReorderItem(
      key: ValueKey('backlog_${node.task?.id ?? index}'),
      index: index,
      visualIndex: visualIndex,
      child: draggableChild,
    );
  }
}
