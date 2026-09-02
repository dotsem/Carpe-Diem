import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/domain/services/deadline_propagation_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/subtask_service.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:uuid/uuid.dart';

class TaskCrudService {
  static const _uuid = Uuid();

  static Future<Task> buildNewTask({
    required ITaskRepository repo,
    required SettingsState settings,
    required String title,
    String? description,
    DateTime? scheduledDate,
    String? projectId,
    bool isUrgent = false,
    DateTime? deadline,
    String? blockedById,
    String? parentId,
    TaskPlacement placement = TaskPlacement.bottom,
    List<String> labelIds = const [],
    List<String> tagIds = const [],
  }) async {
    DateTime? effectiveScheduledDate = scheduledDate;
    String? effectiveProjectId = projectId;
    if (parentId != null) {
      final parentTask = await repo.getById(parentId);
      if (parentTask != null) {
        effectiveScheduledDate ??= parentTask.scheduledDate;
        effectiveProjectId ??= parentTask.projectId;
      }
    }

    final rawList = await TaskReorderService.getRelevantTasksList(
      repo: repo,
      parentId: parentId,
      projectId: effectiveProjectId,
      scheduledDate: effectiveScheduledDate,
      prioritizeDeadlines: settings.prioritizeDeadlines,
      prioritizeOverdue: settings.prioritizeOverdue,
    );

    final resolvedIsUrgent = isUrgent || placement == TaskPlacement.urgent;
    final dummyTask = Task(
      id: '',
      title: '',
      parentId: parentId,
      projectId: effectiveProjectId,
      isUrgent: resolvedIsUrgent,
      deadline: deadline?.normalize,
      scheduledDate: effectiveScheduledDate?.normalize,
      createdAt: DateTime.now(),
    );

    final activeList = rawList
        .where((t) => TaskReorderUtils.inSameGroup(t, dummyTask, settings))
        .toList();
    final computedSortOrder = TaskReorderService.computeSortOrder(
      placement: placement,
      activeList: activeList,
    );

    return Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      scheduledDate: effectiveScheduledDate?.normalize,
      projectId: effectiveProjectId,
      isUrgent: resolvedIsUrgent,
      deadline: deadline?.normalize,
      createdAt: DateTime.now(),
      blockedById: blockedById,
      parentId: parentId,
      sortOrder: computedSortOrder,
      labelIds: labelIds,
      tagIds: tagIds,
    );
  }

  static Future<Task> resolveUpdatedTask({
    required ITaskRepository repo,
    required SettingsState settings,
    required Task task,
    TaskPlacement? placement,
  }) async {
    if (placement == null) return task;

    final rawList = await TaskReorderService.getRelevantTasksList(
      repo: repo,
      parentId: task.parentId,
      projectId: task.projectId,
      scheduledDate: task.scheduledDate,
      prioritizeDeadlines: settings.prioritizeDeadlines,
      prioritizeOverdue: settings.prioritizeOverdue,
    );
    final resolvedIsUrgent = task.isUrgent || placement == TaskPlacement.urgent;
    final targetTask = task.copyWith(isUrgent: resolvedIsUrgent);

    final activeList = rawList
        .where((t) => t.id != task.id)
        .where((t) => TaskReorderUtils.inSameGroup(t, targetTask, settings))
        .toList();
    final computedSortOrder = TaskReorderService.computeSortOrder(
      placement: placement,
      activeList: activeList,
    );
    return targetTask.copyWith(sortOrder: computedSortOrder);
  }

  static Future<Command> buildCreateWithPropagationCommand({
    required ITaskRepository repo,
    required Task task,
    required bool inheritParentDeadline,
  }) async {
    final createCmd = CreateCommand(
      repo: repo,
      item: task,
      id: task.id,
      displayName: task.title,
    );
    final propCmds = await DeadlinePropagationService.buildPropagationCommands(
      repo: repo,
      task: task,
      inheritParentDeadline: inheritParentDeadline,
    );
    if (propCmds.isEmpty) return createCmd;
    return CompoundCommand([
      createCmd,
      ...propCmds,
    ], 'Create "${task.title}" with propagated deadline');
  }

  static Future<Command> buildUpdateWithPropagationCommand({
    required ITaskRepository repo,
    required Task previous,
    required Task next,
    required bool inheritParentDeadline,
  }) async {
    final updateCmd = UpdateCommand(
      repo: repo,
      previous: previous,
      next: next,
      displayName: next.title,
    );
    final propCmds = await DeadlinePropagationService.buildPropagationCommands(
      repo: repo,
      task: next,
      inheritParentDeadline: inheritParentDeadline,
    );
    if (propCmds.isEmpty) return updateCmd;
    return CompoundCommand([
      updateCmd,
      ...propCmds,
    ], 'Update "${next.title}" with propagated deadline');
  }

  static Future<Command> buildDeleteCommand({
    required ITaskRepository repo,
    required Task task,
    required bool deleteSubtasks,
  }) async {
    final subtasks = await SubtaskService.getAllSubtasksFromRepo(
      repo: repo,
      parentId: task.id,
    );

    if (subtasks.isEmpty) {
      return DeleteCommand(
        repo: repo,
        item: task,
        id: task.id,
        displayName: task.title,
      );
    }

    if (deleteSubtasks) {
      final commands = <Command>[
        for (final subtask in subtasks)
          DeleteCommand(
            repo: repo,
            item: subtask,
            id: subtask.id,
            displayName: subtask.title,
          ),
        DeleteCommand(
          repo: repo,
          item: task,
          id: task.id,
          displayName: task.title,
        ),
      ];
      return CompoundCommand(
        commands,
        'Delete "${task.title}" and ${subtasks.length} subtask(s)',
      );
    }

    final commands = <Command>[
      for (final subtask in subtasks)
        UpdateCommand(
          repo: repo,
          previous: subtask,
          next: subtask.copyWith(clearParent: true),
          displayName: subtask.title,
        ),
      DeleteCommand(
        repo: repo,
        item: task,
        id: task.id,
        displayName: task.title,
      ),
    ];
    return CompoundCommand(
      commands,
      'Delete parent "${task.title}" (preserve subtasks)',
    );
  }
}
