import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_markdown_parser.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

extension TaskBulkActions on TaskNotifier {
  Future<void> bulkUpdateTasks({
    required List<String> taskIds,
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

    final commands = <Command>[];
    for (final id in taskIds) {
      final task = tasksState.getById(id) ?? await repo.getById(id);
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
        commands.add(
          UpdateCommand(
            repo: repo,
            previous: task,
            next: updated,
            displayName: task.title,
          ),
        );
        if (settings.inheritParentDeadline && updated.deadline != null) {
          final propCmds =
              await DeadlinePropagationService.buildPropagationCommands(
                repo: repo,
                task: updated,
                inheritParentDeadline: settings.inheritParentDeadline,
              );
          commands.addAll(propCmds);
        }
      }
    }

    if (commands.isNotEmpty) {
      final compound = CompoundCommand(
        commands,
        'Update ${commands.length} tasks',
      );
      await executeCommand(compound);
    }
  }

  Future<void> bulkDeleteTasks({required List<String> taskIds}) async {
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

    final commands = <Command>[];
    for (final id in allIdsToDelete) {
      final task = tasksState.getById(id) ?? await repo.getById(id);
      if (task != null) {
        commands.add(
          DeleteCommand(
            repo: repo,
            item: task,
            id: task.id,
            displayName: task.title,
          ),
        );
      }
    }

    if (commands.isNotEmpty) {
      final compound = CompoundCommand(
        commands,
        'Delete ${commands.length} tasks',
      );
      await executeCommand(compound);
    }
  }

  Future<void> importTasksFromMarkdown({
    required String markdown,
    required String? projectId,
  }) async {
    final projectRepo = ref.read(projectRepositoryProvider);
    final settings = ref.read(settingsProvider);

    final tasks = TaskMarkdownParser.parseMarkdown(markdown);
    if (tasks.isEmpty) return;

    DateTime? projectDeadline;
    if (projectId != null && settings.inheritProjectDeadline) {
      final project = await projectRepo.getById(projectId);
      projectDeadline = project?.deadline;
    }

    final existing = await TaskReorderService.getRelevantTasksList(
      repo: repo,
      parentId: null,
      projectId: projectId,
      scheduledDate: null,
      prioritizeDeadlines: settings.prioritizeDeadlines,
      prioritizeOverdue: settings.prioritizeOverdue,
    );

    final dummy = Task(
      id: '',
      title: '',
      projectId: projectId,
      deadline: projectDeadline?.normalize,
      scheduledDate: null,
      createdAt: DateTime.now(),
    );

    final activeList = existing
        .where((t) => TaskReorderUtils.inSameGroup(t, dummy, settings))
        .toList();

    String? currentRank;
    for (int i = activeList.length - 1; i >= 0 && currentRank == null; i--) {
      currentRank = TaskReorderUtils.getEffectiveRank(activeList, i);
    }

    final commands = <Command>[];
    for (final task in tasks) {
      currentRank = currentRank == null
          ? LexoRank.defaultRank
          : LexoRank.generateBottom(currentRank);
      final resolved = task.copyWith(
        projectId: projectId,
        deadline: projectDeadline,
        sortOrder: currentRank,
      );
      commands.add(
        CreateCommand(
          repo: repo,
          item: resolved,
          id: resolved.id,
          displayName: resolved.title,
        ),
      );
    }

    final compound = CompoundCommand(commands, 'Import ${tasks.length} tasks');
    await executeCommand(compound);
  }
}
