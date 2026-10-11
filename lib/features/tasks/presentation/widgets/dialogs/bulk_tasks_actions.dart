import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/bulk_edit_tasks_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showBulkEditTasksDialog({
  required BuildContext context,
  required WidgetRef ref,
  required List<String> selectedTaskIds,
  required VoidCallback onCompleted,
}) async {
  final result = await showDialog<BulkEditResult>(
    context: context,
    builder: (_) => BulkEditTasksDialog(taskIds: selectedTaskIds),
  );

  if (result != null && context.mounted) {
    await ref
        .read(taskProvider.notifier)
        .bulkUpdateTasks(
          taskIds: selectedTaskIds,
          isUrgent: result.isUrgent,
          updateUrgent: result.updateUrgent,
          scheduledDate: result.scheduledDate,
          updateScheduledDate: result.updateScheduledDate,
          clearScheduledDate: result.clearScheduledDate,
          projectId: result.projectId,
          updateProjectId: result.updateProjectId,
          clearProjectId: result.clearProjectId,
          deadline: result.deadline,
          updateDeadline: result.updateDeadline,
          clearDeadline: result.clearDeadline,
          blockedById: result.blockedById,
          updateBlockedById: result.updateBlockedById,
          clearBlockedById: result.clearBlockedById,
        );
    onCompleted();
  }
}

void showBulkDeleteTasksConfirmDialog({
  required BuildContext context,
  required WidgetRef ref,
  required List<String> selectedTaskIds,
  required VoidCallback onCompleted,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Deletion'),
      content: Text(
        'Are you sure you want to delete ${selectedTaskIds.length} tasks?',
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () async {
            await ref
                .read(taskProvider.notifier)
                .bulkDeleteTasks(taskIds: selectedTaskIds);
            onCompleted();
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
