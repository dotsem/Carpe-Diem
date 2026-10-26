import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
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
      return Column(mainAxisSize: MainAxisSize.min, children: widgets);
    }

    final content = Builder(
      builder: (context) {
        final scope = TaskReorderScope.of(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            final dragSession = ref.watch(taskDragProvider);

            Widget buildList([TaskReorderActiveDrop? activeDrop]) {
              final slotInfo = TaskReorderListSlot.forNodes(
                nodes: nodes,
                activeDrop: activeDrop,
                draggedTaskId: dragSession.draggedTaskId,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(slotInfo.totalCount, (index) {
                  final placeholder = TaskReorderPlaceholderItem.maybeBuild(
                    slotInfo: slotInfo,
                    index: index,
                    activeDrop: activeDrop,
                  );
                  if (placeholder != null) return placeholder;
                  final itemIndex = slotInfo.toOriginalIndex(index);
                  final node = itemIndex < nodes.length
                      ? nodes[itemIndex]
                      : null;
                  final child = widgets[itemIndex];

                  Widget draggableChild = child;
                  if (node?.task != null) {
                    final task = node!.task!;
                    final isSelected = selectedTaskIds.contains(task.id);

                    draggableChild = PlatformDraggable<Task>(
                      key: ValueKey('draggable_${task.id}'),
                      data: task,
                      onDragStarted: () {
                        ref.read(taskDragProvider.notifier).startDrag(task.id);
                      },
                      onDragUpdate: (details) {
                        ref
                            .read(taskDragProvider.notifier)
                            .updatePointerOffset(details.globalPosition);
                      },
                      onDragEnd: (details) {
                        TaskReorderScope.of(context)?.handleDragEnd(details);
                        ref.read(taskDragProvider.notifier).endDrag();
                      },
                      feedback: TaskDragProxy(
                        task: task,
                        selectedCount: isSelected ? selectedTaskIds.length : 1,
                        width: constraints.maxWidth,
                      ),
                      childWhenDragging: const SizedBox.shrink(),
                      child: child,
                    );
                  }

                  return TaskReorderItem(
                    key: node?.task != null
                        ? ValueKey('task_item_${node!.task!.id}')
                        : ValueKey('task_item_$itemIndex'),
                    index: itemIndex,
                    visualIndex: index,
                    child: draggableChild,
                  );
                }),
              );
            }

            if (scope != null) {
              return ValueListenableBuilder<TaskReorderActiveDrop?>(
                valueListenable: scope.activeDropNotifier,
                builder: (context, activeDrop, _) => buildList(activeDrop),
              );
            }
            return buildList();
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
    TaskReorderUtils.dispatchReorder(
      nodes: nodes,
      draggedTask: task,
      newIndex: newIndex,
      selectedTaskIds: selectedTaskIds,
      settings: ref.read(settingsProvider),
      isPlanView: isPlanView,
      onReorder: onReorder,
      onMultiReorder: onMultiReorder,
    );
  }
}
