import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/context_menu_item_tile.dart';
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
  final settings = ref.watch(settingsProvider);

  if (task.status.isTodo) {
    items.addAll([
      _buildStartInProgress(ref, task, onAction),
      _buildMarkAsDone(ref, task, onAction),
    ]);
  } else if (task.status.isInProgress ||
      (!settings.reviewState && task.status.isReview)) {
    items.addAll([
      _buildBackToTodo(ref, task, onAction),
      ?_buildMarkForReview(ref, task, settings.reviewState, onAction),
      _buildMarkAsDone(ref, task, onAction),
    ]);
  } else if (task.status.isReview) {
    items.addAll([
      _buildBackToTodo(ref, task, onAction),
      _buildBackToInProgress(ref, task, onAction),
      _buildMarkAsDone(ref, task, onAction),
    ]);
  } else if (task.status.isDone) {
    items.addAll([
      _buildBackToTodo(ref, task, onAction),
      _buildBackToInProgress(ref, task, onAction),
      ?_buildMarkForReview(ref, task, settings.reviewState, onAction),
    ]);
  }
  return items;
}

PopupMenuItem<void> _buildMarkAsDone(
  WidgetRef ref,
  Task task,
  VoidCallback? onAction,
) {
  final provider = ref.read(taskProvider.notifier);

  return PopupMenuItem(
    onTap: () {
      provider.updateTaskStatus(task, TaskStatus.done);
      onAction?.call();
    },
    child: const ContextMenuItemTile(
      leading: Icon(Icons.check_circle_outline),
      title: 'Mark as Done',
      color: AppColors.success,
    ),
  );
}

PopupMenuItem<void> _buildStartInProgress(
  WidgetRef ref,
  Task task,
  VoidCallback? onAction,
) {
  final provider = ref.read(taskProvider.notifier);

  return PopupMenuItem(
    onTap: () {
      provider.updateTaskStatus(task, TaskStatus.inProgress);
      onAction?.call();
    },
    child: const ContextMenuItemTile(
      leading: Icon(Icons.play_circle_outline),
      title: 'Start (In Progress)',
      color: AppColors.success,
    ),
  );
}

PopupMenuItem<void>? _buildMarkForReview(
  WidgetRef ref,
  Task task,
  bool reviewStateEnabled,
  VoidCallback? onAction,
) {
  final provider = ref.read(taskProvider.notifier);

  return reviewStateEnabled
      ? PopupMenuItem(
          onTap: () {
            provider.updateTaskStatus(task, TaskStatus.review);
            onAction?.call();
          },
          child: const ContextMenuItemTile(
            leading: Icon(Icons.approval),
            title: 'Mark for Review',
          ),
        )
      : null;
}

PopupMenuItem<void> _buildBackToTodo(
  WidgetRef ref,
  Task task,
  VoidCallback? onAction,
) {
  final provider = ref.read(taskProvider.notifier);

  return PopupMenuItem(
    onTap: () {
      provider.updateTaskStatus(task, TaskStatus.todo);
      onAction?.call();
    },
    child: const ContextMenuItemTile(
      leading: Icon(Icons.undo),
      title: 'Back to Todo',
    ),
  );
}

PopupMenuItem<void> _buildBackToInProgress(
  WidgetRef ref,
  Task task,
  VoidCallback? onAction,
) {
  final provider = ref.read(taskProvider.notifier);

  return PopupMenuItem(
    onTap: () {
      provider.updateTaskStatus(task, TaskStatus.inProgress);
      onAction?.call();
    },
    child: const ContextMenuItemTile(
      leading: Icon(Icons.play_arrow),
      title: 'Back to In Progress',
    ),
  );
}

PopupMenuItem<void> buildTopRow(
  BuildContext context,
  WidgetRef ref,
  final Task task,
  final List<Task> tasks,
) {
  final settings = ref.watch(settingsProvider);
  final provider = ref.read(taskProvider.notifier);

  final taskPosition = TaskReorderUtils.getTaskPosition(
    task: task,
    tasks: tasks,
    settings: settings,
  );

  return PopupMenuItem<void>(
    enabled: false,
    child: IconTheme(
      data: IconThemeData(
        color: Theme.of(context).colorScheme.onSurface,
        opacity: 1.0,
      ),
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
                    TaskReorderUtils.moveToBottom(
                      provider,
                      task,
                      tasks,
                      settings,
                    );
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
                    firstDate: AppConstants.appFirstDate,
                    lastDate: DateTime.now().add(
                      Duration(days: settings.maxPlanningDays),
                    ),
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
