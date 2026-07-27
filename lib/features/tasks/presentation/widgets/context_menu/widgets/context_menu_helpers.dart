import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/custom_date_picker_dialog.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';

List<PopupMenuEntry<void>> buildProgressStateItems(
  BuildContext context,
  WidgetRef ref,
  Task task, {
  VoidCallback? onAction,
}) {
  final items = <PopupMenuEntry<void>>[];
  final provider = ref.read(taskProvider.notifier);

  if (task.status.isTodo) {
    items.addAll([
      PopupMenuItem(
        onTap: () {
          provider.startTask(task);
          onAction?.call();
        },
        child: const ListTile(
          leading: Icon(Icons.play_circle_outline, color: AppColors.success),
          title: Text('Start (In Progress)', style: TextStyle(color: AppColors.success)),
          dense: true,
        ),
      ),
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
    ]);
  } else if (task.status.isInProgress) {
    items.addAll([
      PopupMenuItem(
        onTap: () {
          provider.updateTaskStatus(task, TaskStatus.todo);
          onAction?.call();
        },
        child: const ListTile(leading: Icon(Icons.undo), title: Text('Back to Todo'), dense: true),
      ),
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
    ]);
  } else if (task.status.isDone) {
    items.addAll([
      PopupMenuItem(
        onTap: () {
          provider.updateTaskStatus(task, TaskStatus.todo);
          onAction?.call();
        },
        child: const ListTile(leading: Icon(Icons.undo), title: Text('Back to Todo'), dense: true),
      ),
      PopupMenuItem(
        onTap: () {
          provider.updateTaskStatus(task, TaskStatus.inProgress);
          onAction?.call();
        },
        child: const ListTile(leading: Icon(Icons.play_arrow), title: Text('Back to In Progress'), dense: true),
      ),
    ]);
  }
  return items;
}

PopupMenuItem<void> buildTopRow(BuildContext context, WidgetRef ref, final Task task, final List<Task> tasks) {
  final settings = ref.watch(settingsProvider);
  final provider = ref.read(taskProvider.notifier);

  final taskPosition = TaskReorderUtils.getTaskPosition(task: task, tasks: tasks, settings: settings);

  return PopupMenuItem<void>(
    enabled: false,
    child: IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.onSurface, opacity: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_double_arrow_up_rounded),
            tooltip: 'Move to Top',
            onPressed: taskPosition.isFirstInGroup
                ? null
                : () {
                    Navigator.of(context).pop();
                    TaskReorderUtils.moveToTop(provider, task, tasks, settings);
                  },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
            tooltip: 'Move to Bottom',
            onPressed: taskPosition.isLastInGroup
                ? null
                : () {
                    Navigator.of(context).pop();
                    TaskReorderUtils.moveToBottom(provider, task, tasks, settings);
                  },
          ),
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: task.isUrgent
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.error.withAlpha(200),
              // TODO: decide if this is good UX
            ),
            tooltip: task.isUrgent ? 'Mark as Not Urgent' : 'Mark as Urgent',
            onPressed: () {
              Navigator.of(context).pop();
              provider.updateTask(task.copyWith(isUrgent: !task.isUrgent));
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: task.scheduledDate == null ? 'Schedule' : 'Reschedule',
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              final DateTime? result = await showDialog(
                context: context,
                builder: (dialogCtx) {
                  return CustomDatePickerDialog(
                    initialDate: task.scheduledDate ?? DateTime.now(),
                    firstDate: task.scheduledDate ?? AppConstants.appFirstDate,
                    lastDate: DateTime.now().add(Duration(days: settings.maxPlanningDays)),
                  );
                },
              );
              if (result != null && result != task.scheduledDate) {
                provider.updateTask(task.copyWith(scheduledDate: result));
              }
            },
          ),
        ],
      ),
    ),
  );
}
