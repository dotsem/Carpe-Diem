import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Delete, cancel and save row pinned to the bottom of the task form.
class TaskFormFooter extends ConsumerWidget {
  final bool isEditing;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const TaskFormFooter({
    required this.isEditing,
    required this.onDelete,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (isEditing)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Task',
            style: IconButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: onDelete,
          ),
        const Spacer(),
        TextButton(
          onPressed: () => ref.read(rightSidebarProvider.notifier).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onSubmit,
          child: Text(isEditing ? 'Save Changes' : 'Create Task'),
        ),
      ],
    );
  }
}
