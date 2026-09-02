import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/complete_parent_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/blocker_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_group_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
import 'package:carpe_diem/core/utils/task_selection_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'active_task_reorderable_list.dart';

class TaskListSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final int amount;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TaskListSectionHeader({
    super.key,
    required this.title,
    this.color,
    required this.amount,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        SmallChip(
          color: color?.withValues(alpha: 0.15) ?? Colors.transparent,
          borderRadius: 10,
          child: Text(
            '$amount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }
    return content;
  }
}

class TaskHierarchyItem extends ConsumerWidget {
  final TaskHierarchyNode node;
  final bool taskIsOverdue;
  final bool showScheduleDate;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool isReadOnly;
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
        trailing: isReadOnly
            ? const SizedBox.shrink()
            : trailingBuilder?.call(context, parentNode.task),
      );
    } else if (node is TaskNode) {
      final taskNode = node as TaskNode;
      final isNested = taskNode.isBundledUnderParent;
      final projectState = ref.watch(projectProvider);
      final taskNotifier = ref.read(taskProvider.notifier);

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
        trailing: isReadOnly
            ? const SizedBox.shrink()
            : trailingBuilder?.call(context, taskNode.task),
      );
    } else if (node is BlockerIndicatorNode) {
      final blockerNode = node as BlockerIndicatorNode;
      child = BlockerIndicator(
        blockerId: blockerNode.blockerId,
        blockerTitle: blockerNode.blockerTitle,
        blockedTaskId: blockerNode.blockedTaskId,
      );
    } else {
      return const SizedBox.shrink();
    }

    return TaskHierarchyIndicator(depth: node.depth, child: child);
  }
}

class TaskListEmptyPlaceholder extends StatelessWidget {
  final Widget? customPlaceholder;

  const TaskListEmptyPlaceholder({super.key, this.customPlaceholder});

  @override
  Widget build(BuildContext context) {
    if (customPlaceholder != null) return customPlaceholder!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskListKeyboardShortcuts extends StatelessWidget {
  final bool enablePlanShortcut;
  final VoidCallback onMoveNext;
  final VoidCallback onMovePrev;
  final VoidCallback onPlanToday;
  final VoidCallback onPlanTomorrow;
  final Widget child;

  const TaskListKeyboardShortcuts({
    super.key,
    required this.enablePlanShortcut,
    required this.onMoveNext,
    required this.onMovePrev,
    required this.onPlanToday,
    required this.onPlanTomorrow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: Map.fromEntries([
        if (enablePlanShortcut) ...[
          const MapEntry(
            SingleActivator(TodayKeys.keyboardKey, control: true),
            PlanTaskIntent(),
          ),
          const MapEntry(
            SingleActivator(TodayKeys.keyboardKey, control: true, shift: true),
            PlanTaskTomorrowIntent(),
          ),
        ],
      ]),
      child: Actions(
        actions: {
          MoveNextIntent: NonTypingAction<MoveNextIntent>((_) => onMoveNext()),
          MovePrevIntent: NonTypingAction<MovePrevIntent>((_) => onMovePrev()),
          PlanTaskIntent: NonTypingAction<PlanTaskIntent>((_) => onPlanToday()),
          PlanTaskTomorrowIntent: NonTypingAction<PlanTaskTomorrowIntent>(
            (_) => onPlanTomorrow(),
          ),
        },
        child: child,
      ),
    );
  }
}
