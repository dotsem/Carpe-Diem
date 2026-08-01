import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/warning_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/widgets/context_menu_date_items.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/widgets/context_menu_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';

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
        onTap: () => _showAddSubtask(context, task),
        child: const ListTile(
          leading: Icon(Icons.add_task),
          title: Text('Add subtask'),
          dense: true,
        ),
      ),
    PopupMenuItem(
      onTap: () => _showEditTask(context, task),
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

void _showEditTask(BuildContext context, Task task) {
  showDialog(
    context: context,
    builder: (_) => EditTaskDialog(task: task),
  );
}

void _showDeleteTask(
  BuildContext context,
  Task task,
  TaskNotifier provider,
  VoidCallback? onAction,
) {
  final subtasks = provider.getAllSubtasks(task.id);
  final message = subtasks.isEmpty
      ? "Are you sure you want to delete this task?"
      : "Are you sure you want to delete this task and its ${subtasks.length} subtask${subtasks.length > 1 ? 's' : ''}?";

  showDialog(
    context: context,
    builder: (_) => DeleteDialog(
      title: "Delete Task",
      message: message,
      onConfirm: () {
        provider.deleteTask(task);
        onAction?.call();
      },
    ),
  );
}

void _unscheduleTask(
  BuildContext context,
  Task task,
  TaskNotifier provider,
  VoidCallback? onAction,
) {
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

void _showAddSubtask(BuildContext context, Task parentTask) {
  showDialog(
    context: context,
    builder: (_) => AddTaskDialog(
      initialDate: parentTask.scheduledDate,
      initialProjectId: parentTask.projectId,
      initialParentId: parentTask.id,
    ),
  );
}
