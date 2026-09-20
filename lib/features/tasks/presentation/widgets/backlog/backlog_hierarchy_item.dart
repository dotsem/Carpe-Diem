import 'package:carpe_diem/core/utils/task_selection_utils.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_group_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hover_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BacklogHierarchyItem extends ConsumerWidget {
  final TaskHierarchyNode node;
  final List<Task> allTasks;
  final List<String> selectedTaskIds;
  final String? highlightedTaskId;
  final Map<String, FocusNode> itemFocusNodes;
  final ValueChanged<Task> onSelectedChanged;
  final ValueChanged<Task> onEdit;
  final Widget Function(BuildContext, Task)? trailingBuilder;

  const BacklogHierarchyItem({
    super.key,
    required this.node,
    required this.allTasks,
    required this.selectedTaskIds,
    this.highlightedTaskId,
    required this.itemFocusNodes,
    required this.onSelectedChanged,
    required this.onEdit,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider);
    Widget child;

    if (node is ParentContainerNode) {
      final parentNode = node as ParentContainerNode;
      final focusNode = itemFocusNodes.putIfAbsent(
        parentNode.task.id,
        () => FocusNode(debugLabel: 'ParentTask_${parentNode.task.id}'),
      );
      final subtasks = allTasks
          .where((t) => t.parentId == parentNode.task.id)
          .toList();
      final isChecked = TaskSelectionUtils.getParentSelectionState(
        parentId: parentNode.task.id,
        subtasks: subtasks,
        selectedTaskIds: selectedTaskIds.toSet(),
      );

      child = ParentGroupHeader(
        key: ValueKey('parent_${parentNode.task.id}'),
        node: parentNode,
        project: parentNode.task.projectId != null
            ? projectState.getById(parentNode.task.projectId!)
            : null,
        focusNode: focusNode,
        isChecked: isChecked,
        selectionMode: true,
        isHighlighted: parentNode.task.id == highlightedTaskId,
        onToggle: (value) => onSelectedChanged(parentNode.task),
        onTap: () {
          ref
              .read(collapsedSubtasksProvider.notifier)
              .toggleCollapse(parentNode.task.id);
        },
        onContextMenu: (localPosition, renderBox) => showTaskCardContextMenu(
          context,
          ref,
          parentNode.task,
          allTasks,
          localPosition,
          renderBox,
          onAction: () {
            if (selectedTaskIds.contains(parentNode.task.id)) {
              onSelectedChanged(parentNode.task);
            }
          },
        ),
        trailingBuilder: trailingBuilder != null
            ? (context, isHovered) => trailingBuilder!(context, parentNode.task)
            : null,
      );
    } else if (node is TaskNode) {
      final taskNode = node as TaskNode;
      final isNested = taskNode.isBundledUnderParent;
      final focusNode = itemFocusNodes.putIfAbsent(
        taskNode.task.id,
        () => FocusNode(debugLabel: 'Task_${taskNode.task.id}'),
      );

      child = TaskCard(
        key: ValueKey(taskNode.task.id),
        task: taskNode.task,
        project: taskNode.task.projectId != null
            ? projectState.getById(taskNode.task.projectId!)
            : null,
        hideProjectInfo: isNested,
        hideProjectGradient: false,
        isChecked: selectedTaskIds.contains(taskNode.task.id),
        selectionMode: true,
        focusNode: focusNode,
        isHighlighted: taskNode.task.id == highlightedTaskId,
        onToggle: (value) => onSelectedChanged(taskNode.task),
        onTap: () => onEdit(taskNode.task),
        onContextMenu: (localPosition, renderBox) => showTaskCardContextMenu(
          context,
          ref,
          taskNode.task,
          allTasks,
          localPosition,
          renderBox,
          onAction: () {
            if (selectedTaskIds.contains(taskNode.task.id)) {
              onSelectedChanged(taskNode.task);
            }
          },
        ),
        trailingBuilder: (context, isHovered) => trailingBuilder != null
            ? trailingBuilder!(context, taskNode.task)
            : TaskHoverActions(
                task: taskNode.task,
                isHovered: isHovered,
                allTasks: allTasks,
                onEdit: () => onEdit(taskNode.task),
              ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return TaskHierarchyIndicator(depth: node.depth, child: child);
  }
}
