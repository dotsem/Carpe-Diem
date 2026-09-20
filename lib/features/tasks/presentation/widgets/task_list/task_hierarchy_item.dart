import 'package:carpe_diem/core/utils/task_selection_utils.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/complete_parent_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_group_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hover_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskHierarchyItem extends ConsumerWidget {
  final TaskHierarchyNode node;
  final bool taskIsOverdue;
  final bool showScheduleDate;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool isReadOnly;
  final bool isHighlighted;
  final bool selectionMode;
  final Set<String> selectedTaskIds;
  final ValueChanged<Task>? onSelectedChanged;
  final ValueChanged<Task>? onEdit;
  final void Function(BuildContext, Task, Offset, RenderBox)? onContextMenu;
  final Widget Function(BuildContext, Task)? trailingBuilder;

  const TaskHierarchyItem({
    super.key,
    required this.node,
    required this.taskIsOverdue,
    required this.showScheduleDate,
    required this.autofocus,
    this.focusNode,
    required this.isReadOnly,
    this.isHighlighted = false,
    required this.selectionMode,
    required this.selectedTaskIds,
    this.onSelectedChanged,
    this.onEdit,
    this.onContextMenu,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget child;
    if (node is ParentContainerNode) {
      final parentNode = node as ParentContainerNode;
      final projectState = ref.watch(projectProvider);
      final taskState = ref.watch(taskProvider);
      final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
        ..addAll({for (var t in taskState.overdueTasks) t.id: t})
        ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});
      final subtasks = allAvailableTasks.values
          .where((t) => t.parentId == parentNode.task.id)
          .toList();

      child = ParentGroupHeader(
        key: ValueKey('parent_${parentNode.task.id}'),
        node: parentNode,
        project: parentNode.task.projectId != null
            ? projectState.getById(parentNode.task.projectId!)
            : null,
        focusNode: focusNode,
        isChecked: selectionMode
            ? TaskSelectionUtils.getParentSelectionState(
                parentId: parentNode.task.id,
                subtasks: subtasks,
                selectedTaskIds: selectedTaskIds,
              )
            : false,
        selectionMode: selectionMode,
        onToggle: isReadOnly
            ? null
            : (value) => onSelectedChanged?.call(parentNode.task),
        onTap: isReadOnly
            ? null
            : () {
                ref
                    .read(collapsedSubtasksProvider.notifier)
                    .toggleCollapse(parentNode.task.id);
              },
        onContextMenu: isReadOnly
            ? null
            : onContextMenu != null
            ? (pos, box) => onContextMenu!(context, parentNode.task, pos, box)
            : null,
        trailing: isReadOnly ? const SizedBox.shrink() : null,
        trailingBuilder: isReadOnly
            ? null
            : trailingBuilder != null
            ? (context, isHovered) => trailingBuilder!(context, parentNode.task)
            : null,
      );
    } else if (node is TaskNode) {
      final taskNode = node as TaskNode;
      final isNested = taskNode.isBundledUnderParent;
      final projectState = ref.watch(projectProvider);
      final taskNotifier = ref.read(taskProvider.notifier);
      final taskState = ref.watch(taskProvider);
      final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
        ..addAll({for (var t in taskState.overdueTasks) t.id: t})
        ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});

      child = TaskCard(
        key: ValueKey(taskNode.task.id),
        task: taskNode.task,
        project: taskNode.task.projectId != null
            ? projectState.getById(taskNode.task.projectId!)
            : null,
        hideProjectInfo: isNested,
        hideProjectGradient: false,
        isOverdue: taskIsOverdue,
        autofocus: autofocus,
        isHighlighted: isHighlighted,
        focusNode: focusNode,
        onToggle: isReadOnly
            ? (_) {}
            : selectionMode
            ? (value) => onSelectedChanged?.call(taskNode.task)
            : (_) async {
                final conflict = await taskNotifier.toggleComplete(
                  taskNode.task,
                );
                if (conflict != null && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => CompleteParentDialog(conflict: conflict),
                  );
                }
              },
        isChecked: selectionMode
            ? selectedTaskIds.contains(taskNode.task.id)
            : null,
        selectionMode: selectionMode,
        onTap: isReadOnly ? () {} : () => onEdit?.call(taskNode.task),
        showScheduleDate: showScheduleDate,
        onContextMenu: isReadOnly
            ? null
            : onContextMenu != null
            ? (pos, box) => onContextMenu!(context, taskNode.task, pos, box)
            : null,
        leading: isReadOnly ? const SizedBox.shrink() : null,
        trailing: isReadOnly ? const SizedBox.shrink() : null,
        trailingBuilder: isReadOnly
            ? null
            : (context, isHovered) => trailingBuilder != null
                  ? trailingBuilder!(context, taskNode.task)
                  : TaskHoverActions(
                      task: taskNode.task,
                      isHovered: isHovered,
                      allTasks: allAvailableTasks.values.toList(),
                      onEdit: () => onEdit?.call(taskNode.task),
                    ),
      );
    } else {
      child = const SizedBox.shrink();
    }

    return TaskHierarchyIndicator(depth: node.depth, child: child);
  }
}
