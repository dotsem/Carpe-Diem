import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/core/utils/deadline_urgency.dart';
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
    return Tooltip(
      message: 'Overdue task',
      child: SmallChip(
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

    return Tooltip(
      message: 'Status: $label',
      child: SmallChip(
        color: color.withValues(alpha: 0.2),
        child: Text(label, style: TextStyle(fontSize: 11, color: color)),
      ),
    );
  }
}

class ProjectChip extends StatelessWidget {
  final Project? project;

  const ProjectChip({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (project == null) return const SizedBox.shrink();
    final displayColor = project!.color.themeDependentColor(context);
    return Tooltip(
      message: 'Project: ${project!.name}',
      child: SmallChip(
        color: displayColor,
        child: Text(
          project!.name,
          style: TextStyle(fontSize: 11, color: displayColor.contrastColor),
        ),
      ),
    );
  }
}

class DeadlineChip extends StatelessWidget {
  final DateTime deadline;
  final DateTime today;
  final bool isCompleted;

  const DeadlineChip({
    super.key,
    required this.deadline,
    required this.today,
    this.isCompleted = false,
  });

  String _resolveDeadlineText() {
    final date =
        '${months[deadline.month - 1]} ${deadline.day}, ${deadline.year}';
    if (isCompleted) return 'Deadline: $date';
    final days = today.daysUntil(deadline);
    return switch (days) {
      < -1 => 'Overdue by ${-days} days',
      -1 => 'Overdue by 1 day',
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $days days',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgency = isCompleted
        ? DeadlineUrgency.none
        : DeadlineUrgency.of(deadline, today);
    final isLight = theme.brightness == Brightness.light;
    final tint = switch (urgency) {
      DeadlineUrgency.none => theme.colorScheme.onSurfaceVariant,
      DeadlineUrgency.approaching => AppColors.warning,
      DeadlineUrgency.imminent => AppColors.accent,
      DeadlineUrgency.overdue => AppColors.error,
    };
    final foreground = urgency == DeadlineUrgency.approaching && isLight
        ? Color.lerp(tint, Colors.black, 0.45)!
        : tint;

    return Tooltip(
      message:
          'Deadline: ${months[deadline.month - 1]} ${deadline.day}, ${deadline.year}',
      child: SmallChip(
        color: tint.withValues(
          alpha: urgency == DeadlineUrgency.none ? 0.1 : 0.2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 10, color: foreground),
            const SizedBox(width: 4),
            Text(
              _resolveDeadlineText(),
              style: TextStyle(fontSize: 11, color: foreground),
            ),
          ],
        ),
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
    return Tooltip(
      message:
          'Scheduled for ${months[scheduledDate.month - 1]} ${scheduledDate.day}, ${scheduledDate.year}',
      child: SmallChip(
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
