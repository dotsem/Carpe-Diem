import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';

class CascadeDeleteDialog extends StatelessWidget {
  final Task parentTask;
  final List<Task> subtasks;
  final VoidCallback onDeleteParentOnly;
  final VoidCallback onDeleteAll;

  const CascadeDeleteDialog({
    super.key,
    required this.parentTask,
    required this.subtasks,
    required this.onDeleteParentOnly,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final count = subtasks.length;
    final subtaskLabel = count == 1 ? 'subtask' : 'subtasks';

    return SizedDialog(
      maxWidth: 440,
      title: 'Delete Parent Task?',
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
            onDeleteParentOnly();
          },
          child: const Text('Delete parent only'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onDeleteAll();
          },
          child: const Text('Delete all'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${parentTask.title}" has $count $subtaskLabel. Do you want to delete this parent task only (keeping subtasks as standalone tasks), or delete all subtasks as well?',
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
