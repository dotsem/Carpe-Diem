import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

void showTaskCardContextMenu(BuildContext context, WidgetRef ref, Task task, Offset localPosition, RenderBox renderBox) {
  final provider = ref.read(taskProvider.notifier);
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final Offset position = renderBox.localToGlobal(localPosition, ancestor: overlay);

  final items = <PopupMenuEntry<void>>[];

  if (task.status.isTodo) {
    items.add(
      PopupMenuItem(
        onTap: () => provider.startTask(task),
        child: const ListTile(
          leading: Icon(Icons.play_arrow, color: AppColors.success),
          title: Text('Start (In Progress)', style: TextStyle(color: AppColors.success)),
          dense: true,
        ),
      ),
    );
    items.add(
      PopupMenuItem(
        onTap: () => provider.completeTask(task),
        child: const ListTile(
          leading: Icon(Icons.check_circle_outline, color: AppColors.success),
          title: Text('Mark as Done', style: TextStyle(color: AppColors.success)),
          dense: true,
        ),
      ),
    );
  }

  if (task.status.isInProgress) {
    items.add(
      PopupMenuItem(
        onTap: () => provider.updateTaskStatus(task, TaskStatus.todo),
        child: const ListTile(leading: Icon(Icons.undo), title: Text('Back to Todo'), dense: true),
      ),
    );
    items.add(
      PopupMenuItem(
        onTap: () => provider.completeTask(task),
        child: const ListTile(
          leading: Icon(Icons.check_circle_outline, color: AppColors.success),
          title: Text('Mark as Done', style: TextStyle(color: AppColors.success)),
          dense: true,
        ),
      ),
    );
  }

  if (task.status.isDone) {
    items.add(
      PopupMenuItem(
        onTap: () => provider.updateTaskStatus(task, TaskStatus.todo),
        child: const ListTile(leading: Icon(Icons.undo), title: Text('Back to Todo'), dense: true),
      ),
    );
    items.add(
      PopupMenuItem(
        onTap: () => provider.updateTaskStatus(task, TaskStatus.inProgress),
        child: const ListTile(leading: Icon(Icons.play_arrow), title: Text('Back to In Progress'), dense: true),
      ),
    );
  }

  items.addAll([
    PopupMenuItem(
      onTap: () => provider.scheduleTasksForTomorrow([task.id]),
      child: const ListTile(
        leading: Icon(Icons.next_plan_outlined, color: AppColors.info),
        title: Text('Reschedule for Tomorrow', style: TextStyle(color: AppColors.info)),
        dense: true,
      ),
    ),
    if (todayIsEndOfWorkWeek()) ...[
      PopupMenuItem(
        onTap: () => provider.scheduleTasksForNextWorkDay([task.id]),
        child: const ListTile(
          leading: Icon(Icons.work_history_outlined, color: AppColors.info),
          title: Text('Reschedule for Next Week', style: TextStyle(color: AppColors.info)),
          dense: true,
        ),
      ),
    ],
    PopupMenuItem(
      onTap: () => _showEditTask(context, task),
      child: const ListTile(leading: Icon(Icons.edit), title: Text('Edit'), dense: true),
    ),
    if (task.scheduledDate != null)
      PopupMenuItem(
        onTap: () => _unscheduleTask(context, task, provider),
        child: const ListTile(
          leading: Icon(Icons.remove_circle_outline, color: AppColors.warning),
          title: Text('Unschedule', style: TextStyle(color: AppColors.warning)),
          dense: true,
        ),
      ),
    PopupMenuItem(
      onTap: () => _showDeleteTask(context, task, provider),
      child: const ListTile(
        leading: Icon(Icons.delete, color: AppColors.error),
        title: Text('Delete', style: TextStyle(color: AppColors.error)),
        dense: true,
      ),
    ),
  ]);

  showMenu(
    context: context,
    position: RelativeRect.fromRect(Rect.fromLTWH(position.dx, position.dy, 0, 0), Offset.zero & overlay.size),
    items: items,
  );
}

void _showEditTask(BuildContext context, Task task) {
  showDialog(
    context: context,
    builder: (_) => EditTaskDialog(task: task),
  );
}

void _showDeleteTask(BuildContext context, Task task, TaskNotifier provider) {
  showDialog(
    context: context,
    builder: (_) => DeleteDialog(
      title: "Delete Task",
      message: "Are you sure you want to delete this task?",
      onConfirm: () => provider.deleteTask(task),
    ),
  );
}

void _unscheduleTask(BuildContext context, Task task, TaskNotifier provider) {
  if (task.status.isDone) {
    showDialog(
      context: context,
      builder: (_) => WarningDialog(
        title: "Unschedule Completed Task",
        message: "This task is already completed. Are you sure you want to unschedule it?",
        warningText: 'Unschedule',
        onConfirm: () => provider.unScheduleTask(task, resetStatus: true),
      ),
    );
  } else if (task.status.isInProgress) {
    showDialog(
      context: context,
      builder: (_) => WarningDialog(
        title: "Unschedule In Progress Task",
        message: "This task is already in progress. Are you sure you want to unschedule it?",
        warningText: 'Unschedule',
        onConfirm: () => provider.unScheduleTask(task, resetStatus: true),
      ),
    );
  } else {
    provider.unScheduleTask(task);
  }
}
