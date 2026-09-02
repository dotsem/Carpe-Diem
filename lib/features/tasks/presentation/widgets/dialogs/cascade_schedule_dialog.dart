import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CascadeScheduleDialog extends StatelessWidget {
  final Task parentTask;
  final List<Task> subtasks;
  final DateTime? targetDate;
  final bool isUnschedule;
  final VoidCallback onParentOnly;
  final VoidCallback onCascadeAll;

  const CascadeScheduleDialog.schedule({
    super.key,
    required this.parentTask,
    required this.subtasks,
    required this.targetDate,
    required this.onParentOnly,
    required this.onCascadeAll,
  }) : isUnschedule = false;

  const CascadeScheduleDialog.unschedule({
    super.key,
    required this.parentTask,
    required this.subtasks,
    required this.onParentOnly,
    required this.onCascadeAll,
  }) : targetDate = null,
       isUnschedule = true;

  @override
  Widget build(BuildContext context) {
    final count = subtasks.length;
    final subtaskLabel = count == 1 ? 'subtask' : 'subtasks';

    final String title;
    final String promptMessage;
    final String parentOnlyText;
    final String allText;

    if (isUnschedule) {
      title = 'Unschedule Parent Task?';
      promptMessage =
          '"${parentTask.title}" has $count $subtaskLabel. Do you want to unschedule this parent task only, or all of its subtasks as well?';
      parentOnlyText = 'Unschedule parent only';
      allText = 'Unschedule all';
    } else {
      final formattedDate = targetDate != null
          ? (targetDate!.isToday
                ? 'Today'
                : (targetDate!.isTomorrow
                      ? 'Tomorrow'
                      : DateFormat('MMM d').format(targetDate!)))
          : 'selected date';

      title = parentTask.scheduledDate != null
          ? 'Reschedule Parent Task?'
          : 'Schedule Parent Task?';
      final actionWord = parentTask.scheduledDate != null
          ? 'reschedule'
          : 'schedule';
      promptMessage =
          '"${parentTask.title}" has $count $subtaskLabel. Do you want to $actionWord this parent task only, or all of its subtasks to $formattedDate as well?';
      parentOnlyText = '$actionWord parent only';
      allText = '$actionWord all';
    }

    return SizedDialog(
      maxWidth: 440,
      title: title,
      showDefaultActions: false,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onParentOnly();
          },
          child: Text(parentOnlyText),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCascadeAll();
          },
          child: Text(allText),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  promptMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
