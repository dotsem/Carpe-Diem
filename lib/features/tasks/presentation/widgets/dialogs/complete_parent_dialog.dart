import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompleteParentDialog extends ConsumerWidget {
  final SubtaskCompletionConflict conflict;

  const CompleteParentDialog({super.key, required this.conflict});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = conflict.incompleteSubtasks.length;
    final subtaskLabel = count == 1 ? 'subtask is' : 'subtasks are';

    return SizedDialog(
      maxWidth: 420,
      title: 'Complete Parent Task?',
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
            ref
                .read(taskProvider.notifier)
                .completeParentOnly(conflict.parentTask);
          },
          child: const Text('Complete parent only'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(taskProvider.notifier).completeParentWithCascade(conflict);
          },
          child: const Text('Complete all'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${conflict.parentTask.title}" has $count incomplete $subtaskLabel still remaining.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'How would you like to proceed?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
