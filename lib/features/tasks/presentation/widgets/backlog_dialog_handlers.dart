import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/import_from_md_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/bulk_edit_tasks_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';

class BacklogDialogHandlers {
  static void showEditTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => EditTaskDialog(task: task),
    );
  }

  static void showAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );
  }

  static void showImportFromMD(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ImportFromMDDialog(),
    );
  }

  static void showFilterDialog(BuildContext context, WidgetRef ref) async {
    final filterVal = ref.read(filterProvider);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: filterVal.filter),
    );
    if (result != null) {
      ref.read(filterProvider.notifier).setFilter(result);
    }
  }

  static void showBulkEdit(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedTaskIds,
    VoidCallback onCompleted,
  ) async {
    final result = await showDialog<BulkEditResult>(
      context: context,
      builder: (_) => BulkEditTasksDialog(taskIds: selectedTaskIds),
    );

    if (result != null && context.mounted) {
      await ref.read(taskProvider.notifier).bulkUpdateTasks(
        taskIds: selectedTaskIds,
        priority: result.priority,
        updatePriority: result.updatePriority,
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

  static void showBulkDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedTaskIds,
    VoidCallback onCompleted,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${selectedTaskIds.length} tasks?'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        contentTextStyle: Theme.of(context).textTheme.bodyMedium,
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

  static void pickRandomTask(
    BuildContext context,
    WidgetRef ref,
    String searchQuery,
  ) async {
    final taskProviderVal = ref.read(taskProvider);
    final projectProviderVal = ref.read(projectProvider);
    final filter = ref.read(filterProvider).activeFilter;

    var availableTasks = taskProviderVal.unscheduledTasks.where((t) {
      final project = t.projectId != null ? projectProviderVal.getById(t.projectId!) : null;
      return filter.applyToTask(t, project?.labelIds ?? []);
    }).toList();

    if (searchQuery.isNotEmpty) {
      availableTasks = FuzzySearchUtils.search<Task>(
        query: searchQuery,
        items: availableTasks,
        itemToString: (t) => '${t.title} ${t.description ?? ''}',
        threshold: 0.3,
      );
    }

    final randomTask = await ref.read(taskProvider.notifier).pickAndScheduleRandomTask(availableTasks);

    if (randomTask == null) {
      ToastUtils.showInfo('No available tasks to pick from');
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => SizedDialog(
        title: 'We\'ve picked this task for you:',
        showDefaultActions: false,
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Great!'))],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskCard(
              task: randomTask,
              project: randomTask.projectId != null ? projectProviderVal.getById(randomTask.projectId!) : null,
              onToggle: (_) {},
              onTap: () {},
              leading: const SizedBox.shrink(),
              showStrikeThroughOnCompleted: false,
            ),
          ],
        ),
      ),
    );
  }
}
