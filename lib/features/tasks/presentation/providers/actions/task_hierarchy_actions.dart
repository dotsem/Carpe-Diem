import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/task_draft.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

extension TaskHierarchyActions on TaskNotifier {
  Future<void> reparentTasks({
    required List<String> taskIds,
    required String? newParentId,
  }) async {
    Task? parent;
    if (newParentId != null) {
      parent =
          tasksState.getById(newParentId) ?? await repo.getById(newParentId);
      if (parent == null || parent.parentId != null) return;
    }

    final existingSiblings = newParentId != null
        ? await repo.getByParent(newParentId)
        : await reorderService.getRelevantTasksList(
            parentId: null,
            projectId: null,
            scheduledDate: null,
          );

    String? currentRank;
    for (
      var i = existingSiblings.length - 1;
      i >= 0 && currentRank == null;
      i--
    ) {
      currentRank = TaskReorderEngine.getEffectiveRank(existingSiblings, i);
    }

    final commands = <Command>[];
    for (final id in taskIds) {
      final task = tasksState.getById(id) ?? await repo.getById(id);
      if (task == null || task.parentId == newParentId) continue;

      if (newParentId != null) {
        final existingChildren = await repo.getByParent(task.id);
        if (existingChildren.isNotEmpty) continue;
      }

      currentRank = currentRank == null
          ? LexoRank.defaultRank
          : LexoRank.generateBottom(currentRank);

      final updated = task.copyWith(
        parentId: newParentId,
        projectId: newParentId != null ? parent?.projectId : task.projectId,
        sortOrder: currentRank,
      );

      commands.add(
        UpdateCommand(
          repo: repo,
          previous: task,
          next: updated,
          displayName: task.title,
        ),
      );
    }

    if (commands.isNotEmpty) {
      final label = newParentId == null
          ? 'Detach ${commands.length} subtask${commands.length > 1 ? "s" : ""}'
          : 'Move ${commands.length} task${commands.length > 1 ? "s" : ""} to "${parent?.title ?? "parent"}"';
      final compound = CompoundCommand(commands, label);
      await executeCommand(compound);
    }
  }

  Future<void> createParentWithSubtasks({
    required String title,
    required List<String> childTaskIds,
    String? description,
    String? projectId,
    DateTime? scheduledDate,
  }) async {
    var effectiveProjectId = projectId;
    if (effectiveProjectId == null && childTaskIds.isNotEmpty) {
      final childProjects = childTaskIds
          .map((id) => tasksState.getById(id)?.projectId)
          .toSet();
      if (childProjects.length == 1 && childProjects.first != null) {
        effectiveProjectId = childProjects.first;
      }
    }

    final parentTask = await crudService.buildNewTask(
      TaskDraft(
        title: title,
        description: description,
        projectId: effectiveProjectId,
        scheduledDate: scheduledDate,
      ),
    );

    final commands = <Command>[
      CreateCommand(
        repo: repo,
        item: parentTask,
        id: parentTask.id,
        displayName: parentTask.title,
      ),
    ];

    String? currentRank;
    for (final id in childTaskIds) {
      final child = tasksState.getById(id) ?? await repo.getById(id);
      if (child == null) continue;
      final childSubtasks = await repo.getByParent(child.id);
      if (childSubtasks.isNotEmpty) continue;

      currentRank = currentRank == null
          ? LexoRank.defaultRank
          : LexoRank.generateBottom(currentRank);

      final updated = child.copyWith(
        parentId: parentTask.id,
        projectId: parentTask.projectId,
        sortOrder: currentRank,
      );
      commands.add(
        UpdateCommand(
          repo: repo,
          previous: child,
          next: updated,
          displayName: child.title,
        ),
      );
    }

    if (commands.isNotEmpty) {
      final compound = CompoundCommand(
        commands,
        'Group into "${parentTask.title}"',
      );
      await executeCommand(compound);
    }
  }
}
