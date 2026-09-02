import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/warning_dialog.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/cascade_delete_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/cascade_schedule_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/widgets/context_menu_date_items.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/widgets/context_menu_helpers.dart';

void showTaskCardContextMenu(
  BuildContext context,
  WidgetRef ref,
  Task task,
  List<Task> tasks,
  Offset localPosition,
  RenderBox renderBox, {
  VoidCallback? onAction,
}) {
  final provider = ref.read(taskProvider.notifier);
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;
  final Offset position = renderBox.localToGlobal(
    localPosition,
    ancestor: overlay,
  );

  final items = <PopupMenuEntry<void>>[];

  items.add(buildTopRow(context, ref, task, tasks));

  items.addAll(
    buildDateScheduleItems(
      context,
      ref,
      task,
      tasks,
      localPosition,
      renderBox,
      onAction,
    ),
  );

  items.addAll(buildProgressStateItems(context, ref, task, onAction: onAction));

  items.addAll([
    if (task.parentId == null)
      PopupMenuItem(
        onTap: () => context.openRightSidebar(
          AddTaskPanel(
            initialDate: task.scheduledDate,
            initialProjectId: task.projectId,
            initialParentId: task.id,
          ),
        ),
        child: const ListTile(
          leading: Icon(Icons.add_task),
          title: Text('Add subtask'),
          dense: true,
        ),
      ),
    PopupMenuItem(
      onTap: () => context.openRightSidebar(EditTaskPanel(task.id)),

      child: const ListTile(
        leading: Icon(Icons.edit),
        title: Text('Edit'),
        dense: true,
      ),
    ),
    if (task.scheduledDate != null)
      PopupMenuItem(
        onTap: () => _unscheduleTask(context, task, provider, onAction),
        child: const ListTile(
          leading: Icon(Icons.remove_circle_outline, color: AppColors.warning),
          title: Text('Unschedule', style: TextStyle(color: AppColors.warning)),
          dense: true,
        ),
      ),
    PopupMenuItem(
      onTap: () => _showDeleteTask(context, task, provider, onAction),
      child: const ListTile(
        leading: Icon(Icons.delete, color: AppColors.error),
        title: Text('Delete', style: TextStyle(color: AppColors.error)),
        dense: true,
      ),
    ),
  ]);

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    items: items,
  );
}

void _showDeleteTask(
  BuildContext context,
  Task task,
  TaskNotifier provider,
  VoidCallback? onAction,
) {
  final subtasks = provider.getAllSubtasks(task.id);
  if (subtasks.isNotEmpty) {
    showDialog(
      context: context,
      builder: (_) => CascadeDeleteDialog(
        parentTask: task,
        subtasks: subtasks,
        onDeleteParentOnly: () {
          provider.deleteTask(task, deleteSubtasks: false);
          onAction?.call();
        },
        onDeleteAll: () {
          provider.deleteTask(task, deleteSubtasks: true);
          onAction?.call();
        },
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (_) => DeleteDialog(
        title: "Delete Task",
        message: "Are you sure you want to delete this task?",
        onConfirm: () {
          provider.deleteTask(task);
          onAction?.call();
        },
      ),
    );
  }
}

void _unscheduleTask(
  BuildContext context,
  Task task,
  TaskNotifier provider,
  VoidCallback? onAction,
) {
  final subtasks = provider.getAllSubtasks(task.id);
  final hasScheduledSubtasks = subtasks.any((t) => t.scheduledDate != null);

  if (hasScheduledSubtasks) {
    showDialog(
      context: context,
      builder: (_) => CascadeScheduleDialog.unschedule(
        parentTask: task,
        subtasks: subtasks,
        onParentOnly: () {
          provider.unScheduleTask(
            task,
            resetStatus: task.status.isDone || task.status.isInProgress,
            unscheduleChildren: false,
          );
          onAction?.call();
        },
        onCascadeAll: () {
          provider.unScheduleTask(
            task,
            resetStatus: task.status.isDone || task.status.isInProgress,
            unscheduleChildren: true,
          );
          onAction?.call();
        },
      ),
    );
    return;
  }

  void doUnschedule() {
    provider.unScheduleTask(
      task,
      resetStatus: task.status.isDone || task.status.isInProgress,
    );
    onAction?.call();
  }

  if (task.status.isDone || task.status.isInProgress) {
    showDialog(
      context: context,
      builder: (_) => WarningDialog(
        title: "Unschedule Task",
        message:
            "This task is ${task.status.name}. Are you sure you want to unschedule it?",
        warningText: 'Unschedule',
        onConfirm: doUnschedule,
      ),
    );
  } else {
    doUnschedule();
  }
}
