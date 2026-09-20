import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentTaskHoverActions extends ConsumerWidget {
  final Task task;
  final List<Task>? allTasks;
  final VoidCallback? onEdit;
  final VoidCallback? onAction;
  final VoidCallback? onAddSubtask;

  const ParentTaskHoverActions({
    super.key,
    required this.task,
    this.allTasks,
    this.onAction,
    this.onAddSubtask,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Edit parent task',
          onPressed:
              onEdit ??
              () {
                context.openRightSidebar(EditTaskPanel(task.id), ref);
              },
        ),
        IconButton(
          icon: const Icon(Icons.add_task, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Add subtask',
          onPressed:
              onAddSubtask ??
              () {
                context.openRightSidebar(
                  AddTaskPanel(
                    initialDate: task.scheduledDate,
                    initialProjectId: task.projectId,
                    initialParentId: task.id,
                  ),
                  ref,
                );
              },
        ),
        Builder(
          builder: (buttonContext) {
            return IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              color: iconColor,
              visualDensity: VisualDensity.compact,
              tooltip: 'More actions',
              onPressed: () => _openContextMenu(context, buttonContext, ref),
            );
          },
        ),
      ],
    );
  }

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
}
