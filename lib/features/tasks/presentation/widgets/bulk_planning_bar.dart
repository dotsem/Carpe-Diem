import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_button.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/task_selection_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Planning actions (schedule, edit, group, delete) for selected tasks.
class BulkPlanningBar extends ConsumerWidget {
  final List<String> selectedTaskIds;
  final bool disableScheduling;
  final VoidCallback onClearSelection;
  final VoidCallback onScheduleToday;
  final VoidCallback onScheduleTomorrow;
  final VoidCallback onBulkEdit;
  final VoidCallback onBulkDelete;
  final VoidCallback? onGroupTasks;

  const BulkPlanningBar({
    required this.selectedTaskIds,
    required this.onClearSelection,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onBulkEdit,
    required this.onBulkDelete,
    super.key,
    this.disableScheduling = false,
    this.onGroupTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedTaskIds.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final taskState = ref.watch(taskProvider);
    final selectedTasks = selectedTaskIds
        .map(taskState.getById)
        .whereType<Task>();
    final hasMixedProjects = TaskSelectionUtils.hasMixedProjects(selectedTasks);
    final isSingle = selectedTaskIds.length == 1;

    return BulkActionBar(
      label: isSingle
          ? '1 task selected'
          : '${selectedTaskIds.length} tasks selected',
      onClearSelection: onClearSelection,
      actions: [
        BulkActionButton(
          icon: Icons.calendar_today_rounded,
          label: 'Today',
          tooltip: 'Schedule for today',
          color: AppColors.info,
          onPressed: onScheduleToday,
          disabled: disableScheduling,
        ),
        BulkActionButton(
          icon: Icons.next_plan_outlined,
          label: 'Tomorrow',
          tooltip: 'Schedule for tomorrow',
          color: AppColors.info,
          onPressed: onScheduleTomorrow,
          disabled: disableScheduling,
        ),
        BulkActionButton(
          icon: Icons.edit_rounded,
          label: 'Edit',
          tooltip: isSingle ? 'Edit Task' : 'Bulk Edit',
          color: theme.colorScheme.onSurface,
          onPressed: onBulkEdit,
        ),
        if (onGroupTasks != null)
          BulkActionButton(
            icon: Icons.account_tree_outlined,
            label: 'Group',
            color: theme.colorScheme.onSurface,
            disabled: hasMixedProjects,
            tooltip: hasMixedProjects
                ? 'Cannot group tasks across different projects'
                : 'Group into parent task',
            onPressed: hasMixedProjects ? null : onGroupTasks,
          ),
        BulkActionButton(
          icon: Icons.delete_rounded,
          label: 'Delete',
          tooltip: isSingle ? 'Delete Task' : 'Bulk Delete',
          color: AppColors.error,
          onPressed: onBulkDelete,
        ),
      ],
    );
  }
}
