import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class OverdueChip extends StatelessWidget {
  const OverdueChip({super.key});

  @override
  Widget build(BuildContext context) {
    return SmallChip(
      color: AppColors.error.withValues(alpha: 0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_off_outlined,
            size: 10,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          const Text(
            'Overdue',
            style: TextStyle(fontSize: 11, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends ConsumerWidget {
  final Task task;
  const StatusChip({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showReview =
        task.status.isReview && ref.watch(settingsProvider).reviewState;
    final color = showReview ? AppColors.review : AppColors.accent;
    final label = showReview ? 'Review' : 'In Progress';

    return SmallChip(
      color: color.withValues(alpha: 0.2),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class ProjectChip extends StatelessWidget {
  final Project? project;

  const ProjectChip({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final displayColor = project!.color.themeDependentColor(context);
    return SmallChip(
      color: displayColor,
      child: Text(
        project!.name,
        style: TextStyle(fontSize: 11, color: displayColor.contrastColor),
      ),
    );
  }
}

class DeadlineChip extends StatelessWidget {
  final DateTime deadline;

  const DeadlineChip({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    return SmallChip(
      color: Theme.of(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Due: ${months[deadline.month - 1]} ${deadline.day}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduledChip extends StatelessWidget {
  final DateTime scheduledDate;

  const ScheduledChip({super.key, required this.scheduledDate});

  @override
  Widget build(BuildContext context) {
    final isToday = scheduledDate.isToday;
    final isTomorrow = scheduledDate.isTomorrow;
    final scheduledDayTextValue = isToday
        ? 'Today'
        : isTomorrow
        ? 'Tomorrow'
        : '${months[scheduledDate.month - 1]} ${scheduledDate.day}';
    return SmallChip(
      color: AppColors.info.withValues(alpha: 0.15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 10,
            color: AppColors.info,
          ),
          const SizedBox(width: 4),
          Text(
            "Scheduled: $scheduledDayTextValue",
            style: const TextStyle(fontSize: 11, color: AppColors.info),
          ),
        ],
      ),
    );
  }
}

class BlockedChip extends StatelessWidget {
  final String? blockerTitle;

  const BlockedChip({super.key, this.blockerTitle});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final message = blockerTitle != null && blockerTitle!.isNotEmpty
        ? 'Blocked by: $blockerTitle'
        : 'Task is blocked';

    return Tooltip(
      message: message,
      child: SmallChip(
        color: color.withValues(alpha: 0.15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 10, color: color),
            const SizedBox(width: 4),
            Text('Blocked', style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
