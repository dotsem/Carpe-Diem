import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drag_proxy.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveTaskReorderableList extends ConsumerWidget {
  final List<TaskHierarchyNode> nodes;
  final List<Widget> widgets;
  final Set<String> selectedTaskIds;
  final void Function(Task task, String newSortOrder) onReorder;
  final void Function(Map<String, String> newSortOrders)? onMultiReorder;
  final bool isReorderEnabled;

  const ActiveTaskReorderableList({
    super.key,
    required this.nodes,
    required this.widgets,
    this.selectedTaskIds = const {},
    required this.onReorder,
    this.onMultiReorder,
    this.isReorderEnabled = true,
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

    return LayoutBuilder(
      builder: (context, constraints) {
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
              draggableChild = PlatformDraggable<Task>(
                data: task,
                feedback: TaskDragProxy(
                  task: task,
                  selectedCount: isSelected ? selectedTaskIds.length : 1,
                  width: constraints.maxWidth,
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: child),
                child: child,
              );
            }

            return TaskDropZoneWrapper(
              index: index,
              onDrop: (task, newIndex) {
                final settings = ref.read(settingsProvider);
                if (selectedTaskIds.isNotEmpty) {
                  final newSortOrders = TaskReorderUtils.handleMultiReorder(
                    nodes: nodes,
                    draggedTask: task,
                    newIndex: newIndex,
                    selectedTaskIds: selectedTaskIds.toSet(),
                    settings: settings,
                  );
                  if (newSortOrders != null && newSortOrders.isNotEmpty) {
                    onMultiReorder?.call(newSortOrders);
                  } else {
                    final newSortOrder = TaskReorderUtils.handleReorder(
                      nodes: nodes,
                      draggedTask: task,
                      newIndex: newIndex,
                      settings: settings,
                    );
                    if (newSortOrder != null) {
                      onReorder(task, newSortOrder);
                    }
                  }
                } else {
                  final newSortOrder = TaskReorderUtils.handleReorder(
                    nodes: nodes,
                    draggedTask: task,
                    newIndex: newIndex,
                    settings: settings,
                  );
                  if (newSortOrder != null) {
                    onReorder(task, newSortOrder);
                  }
                }
              },
              child: draggableChild,
            );
          },
        );
      },
    );
  }
}
