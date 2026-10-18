import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_hierarchy_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_dotted_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drag_proxy.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
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
  final void Function(Task, int)? onDrop;

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
    this.onDrop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragSession = ref.watch(taskDragProvider);
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
      final isThisTaskDragged = dragSession.draggedTaskId == task.id;
      final showDotted = isThisTaskDragged && dragSession.hasValidTarget;

      draggableChild = PlatformDraggable<Task>(
        data: task,
        onDragStarted: () =>
            ref.read(taskDragProvider.notifier).startDrag(task.id),
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            final dropScope = TaskReorderScope.of(context);
            final activeDrop = dropScope?.activeDropNotifier.value;
            if (activeDrop != null &&
                activeDrop.slot.isValid &&
                !activeDrop.slot.isUnchanged) {
              dropScope?.drop(activeDrop.task, activeDrop.slot.index);
            }
          }
          ref.read(taskDragProvider.notifier).endDrag();
        },
        feedback: TaskDragProxy(
          task: task,
          selectedCount: isSelected ? selectedTaskIds.length : 1,
          width: maxWidth - 32,
        ),
        childWhenDragging: showDotted
            ? TaskCardDottedPlaceholder(child: child)
            : Opacity(opacity: 0.3, child: child),
        child: child,
      );
    }

    return TaskReorderItem(index: index, child: draggableChild);
  }
}
