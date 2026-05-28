import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_timer_provider.dart';

class TaskStatusIndicator extends ConsumerWidget {
  final Task task;
  final bool? isChecked;
  final bool selectionMode;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onToggleAction;

  const TaskStatusIndicator({
    super.key,
    required this.task,
    this.isChecked,
    required this.selectionMode,
    required this.onToggle,
    required this.onToggleAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool effectiveIsChecked = isChecked ?? task.isCompleted;

    if (selectionMode) {
      return Checkbox(
        value: isChecked ?? false,
        onChanged: onToggle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      );
    }

    final timerNotifier = ref.read(taskTimerProvider.notifier);
    final isPending = timerNotifier.isTaskPending(task.id);

    if (task.status.isInProgress) {
      return GestureDetector(
        onTap: onToggleAction,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPending ? AppColors.accent.withValues(alpha: 0.5) : AppColors.accent.withValues(alpha: 0.3),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: isPending ? const Icon(Icons.close, size: 14, color: AppColors.accent) : null,
        ),
      );
    }

    if (task.status.isTodo) {
      return GestureDetector(
        onTap: onToggleAction,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.success),
        ),
      );
    }

    return Checkbox(
      value: effectiveIsChecked,
      onChanged: (value) => onToggleAction(),
      fillColor: isPending ? WidgetStateProperty.all(AppColors.accent.withValues(alpha: 0.5)) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }
}
