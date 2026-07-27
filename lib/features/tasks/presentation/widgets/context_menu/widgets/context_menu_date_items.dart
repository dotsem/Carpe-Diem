import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/selected_date_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
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

  if (task.scheduledDate != null) {
    if (isSelectedDateToday) {
      items.add(
        PopupMenuItem(
          onTap: () {
            provider.scheduleTasksForTomorrow([task.id]);
            onAction?.call();
          },
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
        items.add(
          PopupMenuItem(
            onTap: () {
              provider.scheduleTasksForNextWorkDay([task.id]);
              onAction?.call();
            },
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
          onTap: () {
            provider.scheduleTasksForToday([task.id]);
            onAction?.call();
          },
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
          onTap: () {
            provider.scheduleTasksForNextDay([task.id], selectedDate);
            onAction?.call();
          },
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
        onTap: () {
          provider.scheduleTasksForToday([task.id]);
          onAction?.call();
        },
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
        onTap: () {
          provider.scheduleTasksForTomorrow([task.id]);
          onAction?.call();
        },
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
