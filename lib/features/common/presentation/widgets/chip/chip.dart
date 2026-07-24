import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:flutter/material.dart';

const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class OverdueChip extends StatelessWidget {
  const OverdueChip({super.key});

  @override
  Widget build(BuildContext context) {
    return SmallChip(
      color: AppColors.error.withValues(alpha: 0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off_outlined, size: 10, color: AppColors.error),
          const SizedBox(width: 4),
          const Text('Overdue', style: TextStyle(fontSize: 11, color: AppColors.error)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return SmallChip(
      color: AppColors.accent.withValues(alpha: 0.2),
      child: const Text('In Progress', style: TextStyle(fontSize: 11, color: AppColors.accent)),
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
      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Due: ${months[deadline.month - 1]} ${deadline.day}',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    return SmallChip(
      color: AppColors.info.withValues(alpha: 0.15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 10, color: AppColors.info),
          const SizedBox(width: 4),
          Text(
            'Scheduled: ${months[scheduledDate.month - 1]} ${scheduledDate.day}',
            style: const TextStyle(fontSize: 11, color: AppColors.info),
          ),
        ],
      ),
    );
  }
}
