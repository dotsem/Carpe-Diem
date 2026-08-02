import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_markdown_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskBulkNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> bulkUpdateTasks({
    required List<String> taskIds,
    required List<Task> currentStateTasks,
    required Future<void> Function() onRefresh,
    bool? isUrgent,
    bool updateUrgent = false,
    DateTime? scheduledDate,
    bool updateScheduledDate = false,
    bool clearScheduledDate = false,
    String? projectId,
    bool updateProjectId = false,
    bool clearProjectId = false,
    DateTime? deadline,
    bool updateDeadline = false,
    bool clearDeadline = false,
    String? blockedById,
    bool updateBlockedById = false,
    bool clearBlockedById = false,
  }) async {
    final repo = ref.read(taskRepositoryProvider);
    final projectRepo = ref.read(projectRepositoryProvider);
    final settings = ref.read(settingsProvider);

    DateTime? projectDeadline;
    bool shouldInheritDeadline = false;
    if (updateProjectId &&
        projectId != null &&
        settings.inheritProjectDeadline) {
      final project = await projectRepo.getById(projectId);
      if (project?.deadline != null) {
        projectDeadline = project!.deadline;
        shouldInheritDeadline = true;
      }
    }

    for (final id in taskIds) {
      Task? task;
      try {
        task = currentStateTasks.firstWhere((t) => t.id == id);
      } catch (_) {
        task = await repo.getById(id);
      }

      if (task != null) {
        final updated = task.copyWith(
          isUrgent: updateUrgent ? isUrgent : null,
          scheduledDate: updateScheduledDate ? scheduledDate : null,
          clearScheduledDate: clearScheduledDate,
          projectId: updateProjectId ? projectId : null,
          clearProjectId: clearProjectId,
          deadline: updateDeadline
              ? deadline
              : (shouldInheritDeadline ? projectDeadline : null),
          clearDeadline: clearDeadline,
          blockedById: updateBlockedById ? blockedById : null,
          clearBlockedBy: clearBlockedById,
        );
        await repo.update(updated);
        if (settings.inheritParentDeadline && updated.deadline != null) {
          await DeadlinePropagationService.propagateDeadline(
            repo: repo,
            task: updated,
            inheritParentDeadline: settings.inheritParentDeadline,
          );
        }
      }
    }
    await onRefresh();
    ToastUtils.showSuccess("Updated ${taskIds.length} tasks");
  }

  Future<void> bulkDeleteTasks({
    required List<String> taskIds,
    required Future<void> Function() onRefresh,
  }) async {
    final repo = ref.read(taskRepositoryProvider);
    final allIdsToDelete = <String>{...taskIds};
    for (final id in taskIds) {
      final subtasks = await SubtaskService.getAllSubtasksFromRepo(
        repo: repo,
        parentId: id,
      );
      for (final s in subtasks) {
        allIdsToDelete.add(s.id);
      }
    }
    for (final id in allIdsToDelete) {
      await repo.delete(id);
    }
    await onRefresh();
    ToastUtils.showSuccess('Deleted ${allIdsToDelete.length} tasks');
  }

  Future<void> importTasksFromMarkdown({
    required String markdown,
    required String? projectId,
    required Future<void> Function() onRefresh,
  }) async {
    final repo = ref.read(taskRepositoryProvider);
    final projectRepo = ref.read(projectRepositoryProvider);
    final settings = ref.read(settingsProvider);

    final tasks = TaskMarkdownParser.parseMarkdown(markdown);
    DateTime? projectDeadline;
    if (projectId != null && settings.inheritProjectDeadline) {
      final project = await projectRepo.getById(projectId);
      projectDeadline = project?.deadline;
    }

    for (final task in tasks) {
      await repo.insert(
        task.copyWith(projectId: projectId, deadline: projectDeadline),
      );
    }
    await onRefresh();
    ToastUtils.showSuccess('Imported ${tasks.length} tasks from markdown');
  }
}

final taskBulkProvider = NotifierProvider<TaskBulkNotifier, void>(() {
  return TaskBulkNotifier();
});
