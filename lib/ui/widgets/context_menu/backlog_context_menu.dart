import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/task_status.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/dialogs/edit_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/data/models/task.dart';

void showBacklogContextMenu(
  BuildContext context,
  Task task,
  Offset localPosition,
  RenderBox renderBox, {
  VoidCallback? onAction,
}) {
  final provider = context.read<TaskProvider>();
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  final Offset position = renderBox.localToGlobal(localPosition, ancestor: overlay);

  final items = <PopupMenuEntry<void>>[];

  if (task.status.isTodo) {
    items.add(
      PopupMenuItem(
        onTap: () {
          provider.startTask(task);
          onAction?.call();
        },
        child: const ListTile(
          leading: Icon(Icons.play_arrow, color: AppColors.success),
          title: Text('Start (In Progress)', style: TextStyle(color: AppColors.success)),
          dense: true,
        ),
      ),
    );
    items.add(
      PopupMenuItem(
        onTap: () {
          provider.completeTask(task);
          onAction?.call();
        },
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
        onTap: () {
          provider.updateTaskStatus(task, TaskStatus.done);
          onAction?.call();
        },
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
      onTap: () {
        provider.scheduleTasksForToday([task.id]);
        onAction?.call();
      },
      child: const ListTile(
        leading: Icon(Icons.today, color: AppColors.info),
        title: Text('Schedule for Today', style: TextStyle(color: AppColors.info)),
        dense: true,
      ),
    ),
    PopupMenuItem(
      onTap: () {
        provider.scheduleTasksForTomorrow([task.id]);
        onAction?.call();
      },
      child: const ListTile(
        leading: Icon(Icons.next_plan_outlined, color: AppColors.info),
        title: Text('Schedule for Tomorrow', style: TextStyle(color: AppColors.info)),
        dense: true,
      ),
    ),
    PopupMenuItem(
      onTap: () => _showEditTask(context, task),
      child: const ListTile(leading: Icon(Icons.edit), title: Text('Edit'), dense: true),
    ),
    PopupMenuItem(
      onTap: () {
        provider.deleteTask(task);
        onAction?.call();
      },
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
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<TaskProvider>(),
      child: ChangeNotifierProvider.value(
        value: context.read<ProjectProvider>(),
        child: EditTaskDialog(task: task),
      ),
    ),
  );
}
