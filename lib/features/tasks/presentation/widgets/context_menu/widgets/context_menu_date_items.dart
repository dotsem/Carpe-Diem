import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/selected_date_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/cascade_schedule_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<PopupMenuEntry<void>> buildDateScheduleItems(
  BuildContext context,
  WidgetRef ref,
  final Task task,
  final List<Task> tasks,
  final Offset localPosition,
  final RenderBox renderBox,
  final VoidCallback? onAction,
) {
  final List<PopupMenuEntry<void>> items = [];
  final provider = ref.read(taskProvider.notifier);
  final selectedDate = ref.read(selectedDateProvider);
  final isSelectedDateToday = selectedDate.isToday;

  void scheduleTarget(DateTime targetDate) {
    final subtasks = provider.getAllSubtasks(task.id);
    final incompleteSubtasks = subtasks.where((t) => !t.isCompleted).toList();

    if (incompleteSubtasks.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => CascadeScheduleDialog.schedule(
          parentTask: task,
          subtasks: incompleteSubtasks,
          targetDate: targetDate,
          onParentOnly: () {
            provider.scheduleTaskWithCascade(
              task,
              targetDate,
              cascadeChildren: false,
            );
            onAction?.call();
          },
          onCascadeAll: () {
            provider.scheduleTaskWithCascade(
              task,
              targetDate,
              cascadeChildren: true,
            );
            onAction?.call();
          },
        ),
      );
    } else {
      provider.scheduleTaskWithCascade(
        task,
        targetDate,
        cascadeChildren: false,
      );
      onAction?.call();
    }
  }

  if (task.scheduledDate != null) {
    if (isSelectedDateToday) {
      items.add(
        PopupMenuItem(
          onTap: () =>
              scheduleTarget(DateTime.now().add(const Duration(days: 1))),
          child: const ListTile(
            leading: Icon(Icons.next_plan_outlined, color: AppColors.info),
            title: Text(
              'Reschedule for Tomorrow',
              style: TextStyle(color: AppColors.info),
            ),
            dense: true,
          ),
        ),
      );
      if (todayIsEndOfWorkWeek()) {
        final now = DateTime.now();
        final daysUntilMonday = (8 - now.weekday) % 7 == 0
            ? 7
            : (8 - now.weekday) % 7;
        final nextMonday = now.add(Duration(days: daysUntilMonday));

        items.add(
          PopupMenuItem(
            onTap: () => scheduleTarget(nextMonday),
            child: const ListTile(
              leading: Icon(Icons.next_week_outlined, color: AppColors.info),
              title: Text(
                'Reschedule for Next Week',
                style: TextStyle(color: AppColors.info),
              ),
              dense: true,
            ),
          ),
        );
      }
    } else {
      items.add(
        PopupMenuItem(
          onTap: () => scheduleTarget(DateTime.now()),
          child: ListTile(
            leading: Transform.flip(
              flipX: true,
              child: const Icon(
                Icons.next_plan_outlined,
                color: AppColors.info,
              ),
            ),
            title: const Text(
              'Reschedule for Today',
              style: TextStyle(color: AppColors.info),
            ),
            dense: true,
          ),
        ),
      );
      items.add(
        PopupMenuItem(
          onTap: () => scheduleTarget(
            DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day + 1,
            ),
          ),
          child: const ListTile(
            leading: Icon(Icons.next_plan_outlined, color: AppColors.info),
            title: Text(
              'Reschedule for Next Day',
              style: TextStyle(color: AppColors.info),
            ),
            dense: true,
          ),
        ),
      );
    }
  } else {
    items.addAll([
      PopupMenuItem(
        onTap: () => scheduleTarget(DateTime.now()),
        child: const ListTile(
          leading: Icon(Icons.schedule_outlined, color: AppColors.info),
          title: Text(
            'Schedule for Today',
            style: TextStyle(color: AppColors.info),
          ),
          dense: true,
        ),
      ),
      PopupMenuItem(
        onTap: () =>
            scheduleTarget(DateTime.now().add(const Duration(days: 1))),
        child: const ListTile(
          leading: Icon(Icons.next_plan_outlined, color: AppColors.info),
          title: Text(
            'Schedule for Tomorrow',
            style: TextStyle(color: AppColors.info),
          ),
          dense: true,
        ),
      ),
    ]);
  }
  return items;
}
