import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_dotted_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drag_proxy.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveTaskReorderableList extends ConsumerWidget {
  final List<TaskHierarchyNode> nodes;
  final List<Widget> widgets;
  final Set<String> selectedTaskIds;
  final void Function(Task task, String newSortOrder) onReorder;
  final void Function(Map<String, String> newSortOrders)? onMultiReorder;
  final bool isReorderEnabled;
  final bool isPlanView;

  const ActiveTaskReorderableList({
    super.key,
    required this.nodes,
    required this.widgets,
    this.selectedTaskIds = const {},
    required this.onReorder,
    this.onMultiReorder,
    this.isReorderEnabled = true,
    this.isPlanView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isReorderEnabled) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widgets.length,
        itemBuilder: (context, index) => widgets[index],
      );
    }

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final dragSession = ref.watch(taskDragProvider);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widgets.length,
          itemBuilder: (context, index) {
            final node = index < nodes.length ? nodes[index] : null;
            final child = widgets[index];

            Widget draggableChild = child;
            if (node?.task != null) {
              final task = node!.task!;
              final isSelected = selectedTaskIds.contains(task.id);
              final isThisTaskDragged = dragSession.draggedTaskId == task.id;
              final showDotted =
                  isThisTaskDragged && dragSession.hasValidTarget;

              draggableChild = PlatformDraggable<Task>(
                data: task,
                onDragStarted: () {
                  ref.read(taskDragProvider.notifier).startDrag(task.id);
                },
                onDragEnd: (details) {
                  final scope = TaskReorderScope.of(context);
                  final activeDrop = scope?.activeDropNotifier.value;
                  if (scope != null &&
                      !details.wasAccepted &&
                      activeDrop != null &&
                      activeDrop.slot.isValid &&
                      !activeDrop.slot.isUnchanged) {
                    _handleDrop(ref, activeDrop.task, activeDrop.slot.index);
                  }
                  scope?.onLeaveSlot();
                  ref.read(taskDragProvider.notifier).endDrag();
                },
                feedback: TaskDragProxy(
                  task: task,
                  selectedCount: isSelected ? selectedTaskIds.length : 1,
                  width: constraints.maxWidth,
                ),
                childWhenDragging: showDotted
                    ? TaskCardDottedPlaceholder(child: child)
                    : Opacity(opacity: 0.3, child: child),
                child: child,
              );
            }

            return TaskReorderItem(index: index, child: draggableChild);
          },
        );
      },
    );

    if (TaskReorderScope.of(context) != null) {
      return content;
    }

    return TaskReorderScope(
      nodes: nodes,
      isPlanView: isPlanView,
      onDrop: (task, newIndex) => _handleDrop(ref, task, newIndex),
      child: content,
    );
  }

  void _handleDrop(WidgetRef ref, Task task, int newIndex) {
    final settings = ref.read(settingsProvider);
    if (selectedTaskIds.isNotEmpty) {
      final newSortOrders = TaskReorderUtils.handleMultiReorder(
        nodes: nodes,
        draggedTask: task,
        newIndex: newIndex,
        selectedTaskIds: selectedTaskIds.toSet(),
        settings: settings,
        isPlanView: isPlanView,
      );
      if (newSortOrders != null && newSortOrders.isNotEmpty) {
        onMultiReorder?.call(newSortOrders);
        return;
      }
    }
    final newSortOrder = TaskReorderUtils.handleReorder(
      nodes: nodes,
      draggedTask: task,
      newIndex: newIndex,
      settings: settings,
      isPlanView: isPlanView,
    );
    if (newSortOrder != null) {
      onReorder(task, newSortOrder);
    }
  }
}
