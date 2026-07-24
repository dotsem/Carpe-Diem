import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/dialogs/edit_project_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/bulk_edit_tasks_dialog.dart';

class ProjectDetailDialogHandlers {
  static void showEditTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => EditTaskDialog(task: task),
    );
  }

  static void showAddTask(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(initialProjectId: projectId),
    );
  }

  static void showEditProject(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (_) => EditProjectDialog(project: project),
    );
  }

  static void showDeleteProject(BuildContext context, WidgetRef ref, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteDialog(
        title: 'Delete Project',
        message:
            'Are you sure you want to delete "${project.name}"? This will not delete the tasks, but they will no longer be associated with this project.',
        onConfirm: () async {
          final notifier = ref.read(projectProvider.notifier);
          await notifier.deleteProject(project);
          if (context.mounted) {
            GoRouter.of(context).go('/projects');
          }
        },
      ),
    );
  }

  static void showFilterDialog(BuildContext context, WidgetRef ref) async {
    final filterNotifier = ref.read(filterProvider.notifier);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: ref.read(filterProvider).filter, showProjectFilter: false),
    );
    if (result != null) {
      filterNotifier.setFilter(result);
    }
  }

  static void showBulkEdit({
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

  static void showBulkDeleteConfirm({
    required BuildContext context,
    required WidgetRef ref,
    required List<String> selectedTaskIds,
    required VoidCallback onCompleted,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${selectedTaskIds.length} tasks?'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              await ref.read(taskProvider.notifier).bulkDeleteTasks(selectedTaskIds);
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
}
