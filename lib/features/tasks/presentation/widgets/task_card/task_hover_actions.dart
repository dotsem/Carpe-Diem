import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskHoverActions extends ConsumerWidget {
  final Task task;
  final List<Task>? allTasks;
  final bool isHovered;
  final bool isReadOnly;
  final VoidCallback? onEdit;
  final VoidCallback? onAction;

  const TaskHoverActions({
    super.key,
    required this.task,
    this.allTasks,
    required this.isHovered,
    this.isReadOnly = false,
    this.onEdit,
    this.onAction,
  });

  void _openContextMenu(
    BuildContext context,
    BuildContext buttonContext,
    WidgetRef ref,
  ) {
    final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
    final tasks = allTasks ?? ref.read(taskProvider).tasks;
    showTaskCardContextMenu(
      context,
      ref,
      task,
      tasks,
      Offset.zero,
      renderBox,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isReadOnly) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return IgnorePointer(
      ignoring: !isHovered,
      child: AnimatedOpacity(
        opacity: isHovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: iconColor,
              visualDensity: VisualDensity.compact,
              tooltip: 'Edit task',
              onPressed:
                  onEdit ??
                  () => context.openRightSidebar(EditTaskPanel(task.id), ref),
            ),
            if (task.scheduledDate == null)
              IconButton(
                icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                color: iconColor,
                visualDensity: VisualDensity.compact,
                tooltip: 'Schedule for today',
                onPressed: () => ref
                    .read(taskProvider.notifier)
                    .scheduleTasksForToday([task.id]),
              ),
            IconButton(
              icon: const Icon(Icons.next_plan_outlined, size: 18),
              color: iconColor,
              visualDensity: VisualDensity.compact,
              tooltip: task.scheduledDate == null
                  ? 'Schedule for tomorrow'
                  : 'Reschedule for tomorrow',
              onPressed: () => ref
                  .read(taskProvider.notifier)
                  .scheduleTasksForTomorrow([task.id]),
            ),
            Builder(
              builder: (buttonContext) {
                return IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: iconColor,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'More actions',
                  onPressed: () =>
                      _openContextMenu(context, buttonContext, ref),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
