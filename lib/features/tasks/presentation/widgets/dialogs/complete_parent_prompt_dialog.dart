import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompleteParentPromptDialog extends ConsumerWidget {
  final Task parent;

  const CompleteParentPromptDialog({super.key, required this.parent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedDialog(
      maxWidth: 420,
      title: 'Complete Parent Task?',
      showDefaultActions: false,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          autofocus: true,
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(taskProvider.notifier).completeTask(parent);
          },
          child: const Text('Complete'),
        ),
      ],
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'All subtasks of "${parent.title}" are done. Complete it too?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
